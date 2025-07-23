namespace :splose do |args|
  # bin/rails splose:import_patient_forms business_id=1 force_update=1 api_key=xxx
  task import_patient_forms: :environment do
    def convert_content_to_html(content_json)
      return "<p>No content available</p>" if content_json.blank?

      begin
        content = JSON.parse(content_json)
        html = "<html><head><style>body { font-family: Arial, sans-serif; margin: 20px; } .section { margin-bottom: 30px; } .section-title { font-size: 18px; font-weight: bold; margin-bottom: 15px; border-bottom: 1px solid #ccc; padding-bottom: 5px; } .question { margin-bottom: 15px; } .question-title { font-weight: bold; margin-bottom: 5px; } .answer { margin-left: 10px; padding: 5px; background-color: #f9f9f9; border-left: 3px solid #007cba; }</style></head><body>"

        content.each do |section|
          html += "<div class='section'>"
          html += "<div class='section-title'>#{ERB::Util.html_escape(section['title'] || 'Section')}</div>"

          if section['questions'].present?
            section['questions'].each do |question|
              html += "<div class='question'>"
              html += "<div class='question-title'>#{ERB::Util.html_escape(question['title'] || question['type'])}</div>"

              answer = question['answerText'].presence || question['default'].presence
              if answer.present?
                html += "<div class='answer'>#{ERB::Util.html_escape(answer)}</div>"
              else
                html += "<div class='answer'><em>No answer provided</em></div>"
              end

              html += "</div>"
            end
          end

          html += "</div>"
        end

        html += "</body></html>"
        html
      rescue JSON::ParserError => e
        "<html><body><p>Error parsing form content: #{ERB::Util.html_escape(e.message)}</p></body></html>"
      end
    end

    def map_form_attrs(splose_attrs)
      internal_attrs = {}

      internal_attrs[:description] = splose_attrs['title'].present? ? "#{splose_attrs['title']} imported from Splose" : 'Patient form imported from Splose'
      internal_attrs[:created_at] = Time.parse(splose_attrs['createdAt']) if splose_attrs['createdAt'].present?
      internal_attrs[:updated_at] = Time.parse(splose_attrs['updatedAt']) if splose_attrs['updatedAt'].present?

      internal_attrs
    end

    class SploseImportRecord < ActiveRecord::Base
      self.table_name = 'splose_records'
    end

    def log(what)
      puts what
    end

    business_id = ENV['business_id']
    api_key = ENV['api_key']
    @force_update = ENV['force_update'] == '1' || ENV['force_update'] == 'true'

    if business_id.blank? || api_key.blank?
      raise ArgumentError, "Business ID or API key is missing!"
    end

    @business = Business.find(business_id)

    log "Business to processed: ##{@business.name} | Users: #{@business.users.count}"

    @sync_start_at = Time.current
    log "Import starting: #{@sync_start_at.iso8601}. Business ##{business_id} - #{@business.name}"

    @api_client = SploseApi::Client.new(api_key)

    @total = 0
    @total_creations = 0
    @total_updates = 0
    @total_skipped = 0

    def fetch_with_retry(url, max_attempts = 3)
      attempt = 1

      while attempt <= max_attempts
        begin
          log "API call attempt #{attempt}/#{max_attempts} for URL: #{url}"
          return @api_client.call(:get, url)
        rescue SploseApi::Exception => e
          # Check if it's a 429 rate limit error using status_code property
          is_rate_limit_error = e.respond_to?(:status_code) && e.status_code == 429

          if is_rate_limit_error && attempt < max_attempts
            wait_time = 10 * attempt # Linear backoff: 10, 20, 30 seconds
            log "Rate limit hit (429 Too Many Requests). Status code: #{e.status_code}. Waiting #{wait_time} seconds before retry #{attempt + 1}/#{max_attempts}..."
            sleep(wait_time)
            attempt += 1
          else
            if is_rate_limit_error
              log "Max retry attempts (#{max_attempts}) reached for rate limiting. Exiting import."
              raise "Import failed: Maximum retry attempts reached due to rate limiting (status: #{e.status_code})"
            else
              # Re-raise non-rate-limit errors immediately
              log "Error encountered: #{e.message} (status: #{e.respond_to?(:status_code) ? e.status_code : 'unknown'})"
              raise e
            end
          end
        end
      end
    end

    def fetch_patient_forms(url = '/v1/patient-forms')
      log "Fetching patient forms ... "
      res = fetch_with_retry(url)
      forms = res['data'] || []
      log "Got: #{forms.count} records."

      forms.each do |form_raw_attrs|
        ActiveRecord::Base.transaction do
          import_record = SploseImportRecord.find_or_initialize_by(
            business_id: @business.id,
            reference_id: form_raw_attrs['id'],
            resource_type: 'PatientForm'
          )

          # Find the associated patient using splose_records
          patient_import_record = SploseImportRecord.find_by(
            business_id: @business.id,
            reference_id: form_raw_attrs['patientId'],
            resource_type: 'Patient'
          )

          unless patient_import_record
            log " - SKIPPED Form ##{form_raw_attrs['id']}: Patient not found (patientId: #{form_raw_attrs['patientId']})"
            @total_skipped += 1
            next
          end

          patient = Patient.find_by(id: patient_import_record.internal_id)
          unless patient
            log " - SKIPPED Form ##{form_raw_attrs['id']}: Patient record missing (internal_id: #{patient_import_record.internal_id})"
            @total_skipped += 1
            next
          end

          if import_record.new_record?
            begin
              # Convert content to HTML then PDF
              html_content = convert_content_to_html(form_raw_attrs['content'])
              pdf_content = WickedPdf.new.pdf_from_string(html_content)

              # Create filename
              form_title = form_raw_attrs['title'].presence || 'Patient Form'
              safe_title = form_title.gsub(/[^0-9A-Za-z.\-]/, '_')
              pdf_filename = "#{safe_title}_#{form_raw_attrs['id']}.pdf"

              local_attachment = ::PatientAttachment.new map_form_attrs(form_raw_attrs)
              local_attachment.patient_id = patient.id
              local_attachment.attachment = Extensions::FakeFileIo.new(pdf_filename, pdf_content)
              local_attachment.save!(validate: false)

              import_record.internal_id = local_attachment.id
              import_record.last_synced_at = @sync_start_at
              import_record.save!

              log " - Created: ##{local_attachment.id} | Ref ID: #{form_raw_attrs['id']} | Patient: #{patient.full_name} | Title: #{form_title}"
              @total_creations += 1
            rescue => e
              log " - ERROR creating form ##{form_raw_attrs['id']}: #{e.message}"
              @total_skipped += 1
            end
          else
            # TODO: compare with updated_at on local record is better
            if @force_update || Time.parse(form_raw_attrs['updatedAt']) > import_record.last_synced_at
              log "Form ##{form_raw_attrs['id']} has new update."
              local_attachment = ::PatientAttachment.find_by(
                id: import_record.internal_id
              )

              if local_attachment.nil? # Already synced before but deleted now
                begin
                  # Convert content to HTML then PDF
                  html_content = convert_content_to_html(form_raw_attrs['content'])
                  pdf_content = WickedPdf.new.pdf_from_string(html_content)

                  # Create filename
                  form_title = "#{form_raw_attrs['title']} (Patient form imported from Splose)"
                  safe_title = form_title.gsub(/[^0-9A-Za-z.\-]/, '_')
                  pdf_filename = "#{safe_title}_#{form_raw_attrs['id']}.pdf"

                  local_attachment = ::PatientAttachment.new map_form_attrs(form_raw_attrs)
                  local_attachment.patient_id = patient.id
                  local_attachment.attachment = Extensions::FakeFileIo.new(pdf_filename, pdf_content)
                  local_attachment.save!(validate: false)
                  @total_creations += 1
                rescue => e
                  log " - ERROR recreating form ##{form_raw_attrs['id']}: #{e.message}"
                  @total_skipped += 1
                  next
                end
              else
                # Update existing record
                begin
                  # Convert content to HTML then PDF
                  html_content = convert_content_to_html(form_raw_attrs['content'])
                  pdf_content = WickedPdf.new.pdf_from_string(html_content)

                  # Create filename
                  form_title = "#{form_raw_attrs['title']} (Patient form imported from Splose)"
                  safe_title = form_title.gsub(/[^0-9A-Za-z.\-]/, '_')
                  pdf_filename = "#{safe_title}_#{form_raw_attrs['id']}.pdf"

                  local_attachment.assign_attributes map_form_attrs(form_raw_attrs)
                  local_attachment.attachment = Extensions::FakeFileIo.new(pdf_filename, pdf_content)
                  local_attachment.save!(validate: false)
                  @total_updates += 1
                rescue => e
                  log " - ERROR updating form ##{form_raw_attrs['id']}: #{e.message}"
                  @total_skipped += 1
                  next
                end
              end

              import_record.internal_id = local_attachment.id
              import_record.last_synced_at = @sync_start_at
              import_record.save!
              log " - Updated: ##{local_attachment.id} | Ref ID: #{form_raw_attrs['id']} | Patient: #{patient.full_name}"
            else
              # log "Form ##{form_raw_attrs['id']} already imported. SKIPPED"
            end
          end
        end
      end

      @total += forms.count

      if res['links']['nextPage'].present?
        log "Next page found. Fetching more forms ..."
        sleep(15)
        fetch_patient_forms(res['links']['nextPage'])
      end
    end

    fetch_patient_forms

    log "Import finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Skipped:   #{@total_skipped}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end
