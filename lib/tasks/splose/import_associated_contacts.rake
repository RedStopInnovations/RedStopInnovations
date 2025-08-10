namespace :splose do |args|
  # NOTE: this should be run after `import_contacts` and `import_patients` tasks
  # bin/rails splose:import_associated_contacts business_id=1 api_key=xxx
  task import_associated_contacts: :environment do
    class SploseImportRecord < ActiveRecord::Base
      self.table_name = 'splose_records'
    end

    class ImportContact < ::ActiveRecord::Base
      self.table_name = 'contacts'
    end

    class ImportPatient < ::ActiveRecord::Base
      self.table_name = 'patients'
    end

    def log(what)
      puts "[SPLOSE_IMPORT] #{what}"
    end

    business_id = ENV['business_id']
    api_key = ENV['api_key']
    @force_update = ENV['force_update'] == '1' || ENV['force_update'] == 'true'

    if business_id.blank? || api_key.blank?
      raise ArgumentError, "Business ID or API key is missing!"
    end

    @business = Business.find(business_id)

    log "Business to processed: ##{@business.name} | Users: #{@business.users.count} | Contacts: #{@business.contacts.count}"

    @sync_start_at = Time.current
    log "Import starting: #{@sync_start_at.iso8601}. Business ##{business_id} - #{@business.name}"

    @api_client = SploseApi::Client.new(api_key)

    @total = 0
    @total_processed = 0
    @total_assoc_created = 0

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

    def fetch_contacts(url = '/v1/contacts?include_archived=true')
      log "Fetching contacts ... "
      res = fetch_with_retry(url)
      contacts = res['data'] || []
      log "Got: #{contacts.count} records."

      contacts.each do |contact_raw_attrs|
        ActiveRecord::Base.transaction do
          import_contact_record = SploseImportRecord.find_by(
            business_id: @business.id,
            reference_id: contact_raw_attrs['id'],
            resource_type: 'Contact'
          )

          splose_associated_patient_ids = contact_raw_attrs['associatedPatientIds'] || []

          if import_contact_record && splose_associated_patient_ids.present?
            local_contact = ImportContact.find_by(id: import_contact_record.internal_id)

            splose_associated_patient_ids.each do |splose_patient_id|
              import_patient_record = SploseImportRecord.find_by(
                business_id: @business.id,
                reference_id: splose_patient_id,
                resource_type: 'Patient'
              )

              if import_patient_record
                local_patient = Patient.find_by(business_id: @business.id, id: import_patient_record.internal_id)

                if local_patient
                  ::PatientContact.find_or_create_by!(
                    contact_id: local_contact.id,
                    patient_id: local_patient.id,
                    type: ::PatientContact::TYPE_REFERRER,
                  )
                  @total_assoc_created += 1
                end
              end
            end
          end

          @total_processed += 1
        end
      end

      @total += contacts.count

      if res['links']['nextPage'].present?
        log "Next page found. Fetching more contacts ..."
        sleep(15)
        fetch_contacts(res['links']['nextPage'])
      end
    end

    fetch_contacts

    log "Import finished:"
    log "Total:     #{@total}"
    log "Processed:  #{@total_processed}"
    log "Assoc created:  #{@total_assoc_created}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end