namespace :splose do |args|
  # bin/rails splose:import_cases business_id=1 force_update=1 api_key=xxx
  task import_cases: :environment do
    def map_case_attrs(splose_attrs)
      internal_attrs = {}

      internal_attrs[:case_number] = splose_attrs['caseNumber'].presence
      internal_attrs[:invoice_number] = splose_attrs['appointmentCount'].presence
      internal_attrs[:invoice_total] = splose_attrs['budget'].presence
      internal_attrs[:issue_date] = splose_attrs['issueDate'].present? ? Time.parse(splose_attrs['issueDate']) : nil
      internal_attrs[:end_date] = splose_attrs['expiryDate'].present? ? Date.parse(splose_attrs['expiryDate']) : nil
      internal_attrs[:notes] = "Imported from Splose"

      # Status mapping: true => "Open", false => "Discharged"
      internal_attrs[:status] = splose_attrs['isOpen'] == true ? PatientCase::STATUS_OPEN : PatientCase::STATUS_DISCHARGED

      internal_attrs[:created_at] = Time.parse(splose_attrs['createdAt']) if splose_attrs['createdAt'].present?
      internal_attrs[:updated_at] = Time.parse(splose_attrs['updatedAt']) if splose_attrs['updatedAt'].present?

      # @TODO: check "items" to update allocated appointment counter
      # "items": [
      #   {
      #     "typeId": 1,
      #     "type": "Appointment"
      #   }
      # ]
      internal_attrs
    end

    class SploseImportRecord < ActiveRecord::Base
      self.table_name = 'splose_records'
    end

    class ImportPatientCase < ::ActiveRecord::Base
      self.table_name = 'patient_cases'
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

    log "Business to processed: ##{@business.name} | Users: #{@business.users.count} | Cases: #{@business.patient_cases.count}"

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

    def fetch_cases(url = '/v1/cases')
      log "Fetching cases ... "
      res = fetch_with_retry(url)
      cases = res['data'] || []
      log "Got: #{cases.count} records."

      cases.each do |case_raw_attrs|
        ActiveRecord::Base.transaction do
          import_record = SploseImportRecord.find_or_initialize_by(
            business_id: @business.id,
            reference_id: case_raw_attrs['id'],
            resource_type: 'PatientCase'
          )

          # Find the associated patient using splose_records
          patient_import_record = SploseImportRecord.find_by(
            business_id: @business.id,
            reference_id: case_raw_attrs['patientId'],
            resource_type: 'Patient'
          )

          unless patient_import_record
            log " - SKIPPED Case ##{case_raw_attrs['id']}: Patient not found (patientId: #{case_raw_attrs['patientId']})"
            @total_skipped += 1
            next
          end

          patient = Patient.find_by(id: patient_import_record.internal_id)
          unless patient
            log " - SKIPPED Case ##{case_raw_attrs['id']}: Patient record missing (internal_id: #{patient_import_record.internal_id})"
            @total_skipped += 1
            next
          end

          if import_record.new_record?
            local_case = ImportPatientCase.new map_case_attrs(case_raw_attrs)

            local_case.patient_id = patient.id
            local_case.save!

            import_record.internal_id = local_case.id
            import_record.last_synced_at = @sync_start_at
            import_record.save!
            log " - Created: ##{local_case.id} | Ref ID: #{case_raw_attrs['id']} | Patient: #{patient.full_name}"
            @total_creations += 1
          else
            # TODO: compare with updated_at on local record is better
            if @force_update || Time.parse(case_raw_attrs['updatedAt']) > import_record.last_synced_at
              log "Case ##{case_raw_attrs['id']} has new update."
              local_case = ImportPatientCase.find_by(
                id: import_record.internal_id
              )
              if local_case.nil? # Already synced before but deleted now
                local_case = ImportPatientCase.new
                local_case.patient_id = patient.id
                @total_creations += 1
              else
                @total_updates += 1
              end

              local_case.assign_attributes map_case_attrs(case_raw_attrs)

              local_case.save!
              import_record.internal_id = local_case.id
              import_record.last_synced_at = @sync_start_at
              import_record.save!
              log " - Updated: ##{local_case.id} | Ref ID: #{case_raw_attrs['id']} | Patient: #{patient.full_name}"
            else
              # log "Case ##{case_raw_attrs['id']} already imported. SKIPPED"
            end
          end
        end
      end

      @total += cases.count

      if res['links']['nextPage'].present?
        log "Next page found. Fetching more cases ..."
        sleep(5)
        fetch_cases(res['links']['nextPage'])
      end
    end

    fetch_cases

    log "Import finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Skipped:   #{@total_skipped}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end