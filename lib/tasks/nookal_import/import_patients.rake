# Example: rails nookal_import:import_patients business_id=135 csv=tmp/nookal/patients.csv perform_geocode=1
namespace :nookal_import do
  task import_patients: :environment do
    @logger = Logger.new("tmp/nookal_import_patients_#{Time.now.to_i}.log")
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
    log "Starting import nookal patients for business: ##{ @business.id } - #{ @business.name }"

    perform_geocode = ['1', 1, 'y'].include?(ENV['perform_geocode'])

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
        nookal_attrs = row.to_h

        ref_id = nookal_attrs.fetch 'ClientID'

        import_record = NookalImport::ImportRecord.find_or_initialize_by(
          reference_id: ref_id,
          resource_type: 'Patient',
          business_id: @business.id
        )

        local_attrs = NookalImport::Mapper::Patient.build nookal_attrs

        if import_record.new_record? || !LocalPatient.exists?(id: import_record.internal_id)
          local_patient = LocalPatient.new
        else
          local_patient = LocalPatient.find_by(id: import_record.internal_id)
        end

        local_patient.business_id = @business.id
        local_patient.assign_attributes local_attrs

        patient_full_address = [
          local_patient.address1, local_patient.address2, local_patient.city,
          local_patient.state, local_patient.postcode, local_patient.country
        ].map(&:presence).compact.join(' ')

        if patient_full_address.present? && perform_geocode
          begin
            lat, lng = Geocoder.coordinates(patient_full_address)
            if lat.present? && lng.present?
              local_patient.latitude = lat
              local_patient.longitude = lng
            end
            sleep(0.1)
          rescue => e
            puts "Geocode for `#{cliniko_patient.full_address}` failed. Error: #{e.message}"
          end
        end

        local_patient.save!

        if local_patient.new_record?
          log "- Client created. Ref ID: #{ref_id}. Progress: #{imported_count + 1}"
        else
          log "- Client updated. Ref ID: #{ref_id}. Progress: #{imported_count + 1}"
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
