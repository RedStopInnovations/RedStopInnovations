# Example: rails healthkit:import_customed_specialist business_id=135 csv=tmp/healthkit/specialist_list.csv
namespace :healthkit do
  task import_customed_specialist: :environment do
    class LocalContact < ::ActiveRecord::Base
      self.table_name = 'contacts'
    end

    def log(what)
      puts what
    end

    business_id = ENV['business_id']
    csv_path = ENV['csv']

    if business_id.blank? || csv_path.blank?
      raise ArgumentError, "Business ID or CSV path is missing!"
    end

    @business = Business.find(business_id)
    log "Starting import specialist for business: ##{ @business.id } - #{ @business.name }"

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
        puts healthkit_attrs.inspect

        ref_id = Digest::MD5.hexdigest(healthkit_attrs.to_s)

        import_record = HealthkitImporting::ImportRecord.find_or_initialize_by(
          reference_id: ref_id,
          resource_type: 'Specialist',
          business_id: @business.id
        )

        local_attrs = HealthkitImporting::Mapper::CustomedSpecialist.build healthkit_attrs

        if import_record.new_record? || !LocalContact.exists?(id: import_record.internal_id)
          local_contact = LocalContact.new
        else
          local_contact = LocalContact.find_by(id: import_record.internal_id)
        end

        local_contact.business_id = @business.id
        local_contact.assign_attributes local_attrs
        local_contact.save!

        if local_contact.new_record?
          log "- Specialist import. Ref ID: #{ref_id}. Progress: #{imported_count}"
        else
          log "- Specialist updated. Ref ID: #{ref_id}. Progress: #{imported_count}"
        end

        import_record.assign_attributes(
          internal_id: local_contact.id,
          last_synced_at: Time.current
        )

        import_record.save!
        imported_count += 1
      rescue => e
        failed_refs << ref_id
        log "ERROR: #{ref_id}| Message: #{e.message}"
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