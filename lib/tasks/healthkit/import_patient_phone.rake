# Example: rails healthkit:import_patient_phone business_id=135 csv=tmp/healthkit/patientphone.csv
namespace :healthkit do
  task import_patient_phone: :environment do
    @logger = Logger.new("tmp/healthkit_import_patient_phone_log_#{Time.now.to_i}.log")
    class LocalPatient < ::ActiveRecord::Base
      self.table_name = 'patients'
    end

    def log(what)
      puts what
      @logger.info what
    end

    business_id = ENV['business_id']
    csv_path = ENV['csv']
    limit = ENV['limit'].to_i

    if business_id.blank? || csv_path.blank?
      raise ArgumentError, "Business ID or CSV path is missing!"
    end

    @business = Business.find(business_id)
    log "Starting import client phone for business: ##{ @business.id } - #{ @business.name }"

    print "Continue? (Y/n): "
    confirm = STDIN.gets.chomp

    if confirm != 'Y'
      log "Import cancelled!"
      exit
    end

    imported_count = 0
    failed_refs = []

    CSV.foreach(Rails.root.join(csv_path), headers: true) do |row|
      begin
        healthkit_attrs = row.to_h
        patient_ref_id = healthkit_attrs.fetch 'patient'

        import_record = HealthkitImporting::ImportRecord.find_or_initialize_by(
          reference_id: patient_ref_id,
          resource_type: 'Patient',
          business_id: @business.id
        )

        if import_record.persisted?
          local_patient = LocalPatient.find_by(id: import_record.internal_id)
        end

        if local_patient.nil?
          log "- Patient ref id #{patient_ref_id} is not exist. Skipped."
        else

          phone_type = healthkit_attrs['type']
          phone_number = healthkit_attrs['number']

          if phone_number.present?
            phone_number_formatted = TelephoneNumber.parse(
              phone_number,
              'AU'
            ).e164_number
          end

          case healthkit_attrs['type']
          when 'Mobile'
            local_patient.mobile = phone_number
            local_patient.mobile_formated = phone_number_formatted
          when 'Landline', 'Work'
            local_patient.phone = phone_number
            local_patient.phone_formated = phone_number_formatted
          when 'Fax'
            local_patient.fax = phone_number
          end

          local_patient.save!

          imported_count += 1
          log "- Progress: #{imported_count}"
        end

      rescue => e
        failed_refs << patient_ref_id
        log "ERROR: #{patient_ref_id}| Message: #{e.message}"
      end

      if (limit > 0) && limit == imported_count
        break
      end
    end

    log "Import done!"
    log "Imported: #{imported_count}"
    log "Fails:   #{failed_refs.count}"
    unless failed_refs.empty?
      log "Failed refs: [#{failed_refs.join(',')}]"
    end

  end
end
