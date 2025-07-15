# Example: rails healthkit:import_patient business_id=135 csv=tmp/healthkit/patient.csv
namespace :healthkit do
  task import_patient: :environment do
    @logger = Logger.new("tmp/healthkit_import_patient_log_#{Time.now.to_i}.log")
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
    log "Starting import healthkit clients for business: ##{ @business.id } - #{ @business.name }"

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

        ref_id = healthkit_attrs.fetch 'id'

        import_record = HealthkitImporting::ImportRecord.find_or_initialize_by(
          reference_id: ref_id,
          resource_type: 'Patient',
          business_id: @business.id
        )

        local_attrs = HealthkitImporting::Mapper::Patient.build healthkit_attrs

        if import_record.new_record? || !LocalPatient.exists?(id: import_record.internal_id)
          local_patient = LocalPatient.new
        else
          local_patient = LocalPatient.find_by(id: import_record.internal_id)
        end

        local_patient.business_id = @business.id
        local_patient.assign_attributes local_attrs
        local_patient.save!

        if local_patient.new_record?
          log "- File created. Ref ID: #{ref_id}. Progress: #{imported_count}"
        else
          log "- File updated. Ref ID: #{ref_id}. Progress: #{imported_count}"
        end

        import_record.assign_attributes(
          internal_id: local_patient.id,
          last_synced_at: Time.current
        )

        import_record.save!
        imported_count += 1
      rescue => e
        failed_refs << ref_id
        log "ERROR: #{ref_id}| Message: #{e.message}"
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
