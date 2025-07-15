#rake coreplus:import_patients business_id=135 csv=
namespace :coreplus do
  task import_patients: :environment do
    @logger = Logger.new("tmp/coreplus_import_patients_log_#{Time.now.to_i}.log")
    class ImportPatient < ::ActiveRecord::Base
      self.table_name = 'patients'

      store_accessor :medicare_details,
                     :medicare_card_number,
                     :medicare_card_irn

      store_accessor :dva_details,
                     :dva_file_number
    end

    def log(what)
      puts what
      @logger.info what
    end

    business_id = ENV['business_id']
    csv_path = ENV['csv']
    limit = ENV['limit'].to_i

    # @perform_geocode = ['1', '1'].include?(ENV['geocode'])

    if business_id.blank? || csv_path.blank?
      raise ArgumentError, "Business ID or CSV path is missing!"
    end

    @business = Business.find(business_id)
    log "Starting import clients for business: ##{ @business.id } - #{ @business.name }"
    print "Continue? (Y/n): "
    confirm = STDIN.gets.chomp
    if confirm != 'Y'
      log "Import cancelled!"
      exit
    end
    count = 0
    imported_count = 0
    failed_refs = []
    CSV.open("tmp/coreplus_import_patients_log_#{Time.now.to_i}.csv", "wb") do |csv|
      csv << ["ref ID", "name", "input address", "address1", "address2", "city", "state", "postcode", "mobile", "phone"]
      CSV.foreach(Rails.root.join(csv_path), headers: true, col_sep: "\t", encoding: 'ISO-8859-1') do |row|
        begin
          coreplus_attrs = row.to_h
          ref_id = coreplus_attrs.fetch 'clientID'
          log "##{count} - Ref ID: #{ref_id}"
          unless CoreplusImporting::ImportRecord.exists?(
            reference_id: ref_id,
            resource_type: 'Patient',
            business_id: @business.id
          )
            local_attrs = CoreplusImporting::Mapper::Patient.build coreplus_attrs
            csv << [
              ref_id,
              local_attrs[:full_name],
              [coreplus_attrs['address'], coreplus_attrs['suburb'], coreplus_attrs['postcode']].compact.join(', '),
              local_attrs[:address1],
              local_attrs[:address2],
              local_attrs[:city],
              local_attrs[:state],
              local_attrs[:postcode],
              local_attrs[:mobile],
              local_attrs[:phone],
            ]
            import_patient = ImportPatient.new(
              local_attrs.merge(business_id: business_id)
            )
            import_patient.save!
            import_log = CoreplusImporting::ImportRecord.new(
              business_id: @business.id,
              reference_id: ref_id,
              resource_type: 'Patient',
              internal_id: import_patient.id,
              last_synced_at: Time.current
            )

            import_log.save!
            imported_count += 1
          else
            log " -- The patient is already imported. Skipped."
          end
        rescue => e
          failed_refs << ref_id
          log "ERROR: #{ref_id}| Message: #{e.message}"
        end
        count += 1
        if (count % 100) == 0
          log "Sleeping ... zzZ"
          sleep(5)
        end
        if (limit > 0) && limit == count
          break
        end
      end
    end
    log "Import done!"
    log "Scanned:  #{count}"
    log "Imported: #{imported_count}"
    log "Fails:   #{failed_refs.count}"
    unless failed_refs.empty?
      log "Failed refs: [#{failed_refs.join(',')}]"
    end
  end
end
