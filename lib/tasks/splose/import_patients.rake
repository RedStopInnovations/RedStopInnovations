namespace :splose do |args|
  # bin/rails splose:import_patients business_id=1 api_key=xxx force_update=1
  task import_patients: :environment do
    def map_patient_attrs(splose_attrs)
      internal_attrs = {}

      internal_attrs[:title] = splose_attrs['title'].presence
      internal_attrs[:first_name] = splose_attrs['firstname'].presence
      internal_attrs[:last_name] = splose_attrs['lastname'].presence
      internal_attrs[:dob] = splose_attrs['birthdate'].presence
      internal_attrs[:email] = splose_attrs['email'].presence
      internal_attrs[:timezone] = splose_attrs['timezone'].presence

      if splose_attrs['archived']
        internal_attrs[:archived_at] = splose_attrs['updatedAt']
      else
        internal_attrs[:archived_at] = nil
      end

      internal_attrs[:full_name] = "#{internal_attrs[:first_name]} #{internal_attrs[:last_name]}".strip

      internal_attrs[:address1] = splose_attrs['addressL1'].presence
      internal_attrs[:address2] = splose_attrs['addressL2'].presence
      internal_attrs[:city] = splose_attrs['city'].presence
      internal_attrs[:postcode] = splose_attrs['postalCode'].presence
      internal_attrs[:state] = splose_attrs['state'].presence
      internal_attrs[:country] = splose_attrs['country'].presence

      country = internal_attrs[:country] || 'Australia'

      if splose_attrs['phoneNumbers'].present?
        splose_attrs['phoneNumbers'].each do |phone_number|
          if phone_number['type'] == 'Mobile'
            internal_attrs[:mobile] = phone_number['phoneNumber']
            internal_attrs[:mobile_formated] = TelephoneNumber.parse(internal_attrs[:mobile], country).international_number
          end
          if phone_number['type'] == 'Home'
            internal_attrs[:phone] = phone_number['phoneNumber']
            internal_attrs[:phone_formated] = TelephoneNumber.parse(internal_attrs[:phone], country).international_number
          end
        end
      end

      internal_attrs[:created_at] = Time.parse(splose_attrs['createdAt']) if splose_attrs['createdAt'].present?
      internal_attrs[:updated_at] = Time.parse(splose_attrs['updatedAt']) if splose_attrs['updatedAt'].present?
      internal_attrs[:deleted_at] = Time.parse(splose_attrs['deletedAt']) if splose_attrs['deletedAt'].present?

      internal_attrs
    end

    class SploseImportRecord < ActiveRecord::Base
      self.table_name = 'splose_records'
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

    log "Business to processed: ##{@business.name} | Users: #{@business.users.count} | Patients: #{@business.patients.count}"

    @sync_start_at = Time.current
    log "Import starting: #{@sync_start_at.iso8601}. Business ##{business_id} - #{@business.name}"

    @api_client = SploseApi::Client.new(api_key)

    @total = 0
    @total_creations = 0
    @total_updates = 0

    def fetch_patients(url = '/v1/patients')
      log "Fetching patients ... "
      res = @api_client.call(:get, url)
      patients = res['data'] || []
      log "Got: #{patients.count} records."

      patients.each do |patient_raw_attrs|
        ActiveRecord::Base.transaction do
          patient_raw_attrs

          import_record = SploseImportRecord.find_or_initialize_by(
            business_id: @business.id,
            reference_id: patient_raw_attrs['id'],
            resource_type: 'Patient'
          )

          if import_record.new_record?
            local_patient = ImportPatient.new map_patient_attrs(patient_raw_attrs)

            local_patient.business_id = @business.id
            local_patient.save!

            import_record.internal_id = local_patient.id
            import_record.last_synced_at = @sync_start_at
            import_record.save!
            log " - Created: ##{local_patient.id} | Ref ID: #{patient_raw_attrs['id']}"
            @total_creations += 1
          else
            # TODO: compare with updated_at on local record is better
            if @force_update || Time.parse(patient_raw_attrs['updatedAt']) > import_record.last_synced_at
              log "Patient ##{patient_raw_attrs['id']} has new update."
              local_patient = ImportPatient.find_by(
                id: import_record.internal_id
              )
              if local_patient.nil? # Already synced before but deleted now
                local_patient = ImportPatient.new
                @total_creations += 1
              else
                @total_updates += 1
              end

              local_patient.assign_attributes map_patient_attrs(patient_raw_attrs)

              local_patient.save!
              import_record.internal_id = local_patient.id
              import_record.last_synced_at = @sync_start_at
              import_record.save!
              log " - Updated: ##{local_patient.id} | Ref ID: #{patient_raw_attrs['id']}"
            else
              # log "Patient ##{patient_raw_attrs['id']} already imported. SKIPPED"
            end
          end
        end
      end

      @total += patients.count

      if res['links']['nextPage'].present?
        log "Next page found. Fetching more patients ..."
        sleep(30)
        fetch_patients(res['links']['nextPage'])
      end
    end

    fetch_patients

    log "Import finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end
