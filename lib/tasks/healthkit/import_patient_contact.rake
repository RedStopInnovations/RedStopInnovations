# Example: rails healthkit:import_patient_contact business_id=135 csv=tmp/healthkit/patientcontact.csv
# Note: should clean next_of_kin column first
namespace :healthkit do
  task import_patient_contact: :environment do
    @logger = Logger.new("tmp/healthkit_import_patient_contact_log_#{Time.now.to_i}.log")
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
    log "Starting import client contact for business: ##{ @business.id } - #{ @business.name }"

    print "Continue? (Y/n): "
    confirm = STDIN.gets.chomp

    if confirm != 'Y'
      log "Import cancelled!"
      exit
    end

    imported_count = 0
    failed_refs = []
    imported_ids = []

    CSV.foreach(Rails.root.join(csv_path), headers: true) do |row|
      begin
        healthkit_attrs = row.to_h
        patient_ref_id = healthkit_attrs.fetch 'id'

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

          # Add contact as next_of_kin
          contact_name = [
            healthkit_attrs['forename'].presence,
            healthkit_attrs['surname'].presence
          ].compact().join(' ')

          relationship = healthkit_attrs['relationship']

          if relationship.blank?
            relationship = 'Unknown'
          end

          next_of_kin_append_line = "#{contact_name} (#{relationship}) #{healthkit_attrs['phone']} #{healthkit_attrs['email']}".strip

          if imported_ids.include?(local_patient.id) && local_patient.next_of_kin.present?
            local_patient.next_of_kin = local_patient.next_of_kin + "\n" + next_of_kin_append_line
          else
            local_patient.next_of_kin = next_of_kin_append_line
          end

          local_patient.save!

          imported_count += 1
          imported_ids << local_patient.id
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
