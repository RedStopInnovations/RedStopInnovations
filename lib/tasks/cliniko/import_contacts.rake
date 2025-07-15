namespace :cliniko do |args|
  # bin/rails cliniko:import_contacts business_id=xxx api_key=xxx api_shard=xxx
  task import_contacts: :environment do

    class ImportContact < ::ActiveRecord::Base
      self.table_name = 'contacts'
    end

    def log(what)
      puts "[CLINIKO_IMPORT] #{what}"
    end

    business_id = ENV['business_id']
    api_key = ENV['api_key']
    api_shard = ENV['api_shard']

    if business_id.blank? || api_key.blank?
      raise ArgumentError, "Business ID or API key is missing!"
    end

    @business = Business.find(business_id)

    log "Business to processed: ##{@business.name} | Users: #{@business.users.count} | Patients: #{@business.patients.count} | Created: #{@business.created_at.strftime('%Y-%m-%d')}"

    print "Type \"OK\" to continue: "
    continue_confirm = STDIN.gets.chomp
    if continue_confirm != 'OK'
      log "Cancelled due to not confirmed"
      exit(0)
    end

    @sync_start_at = Time.current
    log "Import starting: #{@sync_start_at.iso8601}. Business ##{business_id} - #{@business.name}"

    @api_client = ClinikoApi::Client.new(api_key, api_shard)

    @total = 0
    @total_creations = 0
    @total_updates = 0

    def fetch_contacts(url = '/contacts')
      log "Fetching contacts ... "
      res = @api_client.call(:get, url, per_page: 100)
      contacts = res['contacts']
      log "Got: #{contacts.count} records."

      contacts.each do |raw_attrs|
        ActiveRecord::Base.transaction do
          cliniko_contact = ClinikoApi::Resource::Contact.new
          cliniko_contact.attributes = raw_attrs
          import_record = ClinikoImporting::ImportRecord.find_or_initialize_by(
            business_id: @business.id,
            reference_id: cliniko_contact.id,
            resource_type: 'Contact'
          )

          if import_record.new_record?
            local_contact = ImportContact.new(
              ClinikoImporting::Mapper::Contact.build(cliniko_contact)
            )

            local_contact.business_id = @business.id
            local_contact.save!

            import_record.internal_id = local_contact.id
            import_record.last_synced_at = @sync_start_at
            import_record.save!
            log " - Created: ##{local_contact.id} | Ref ID: #{cliniko_contact.id}"
            @total_creations += 1
          else
            # TODO: compare with updated_at on local record is better
            if cliniko_contact.updated_at > import_record.last_synced_at
              log "Cliniko contact ##{cliniko_contact.id} has new update."
              local_contact = ImportContact.find_by(
                id: import_record.internal_id
              )

              if local_contact.nil? # Already synced before but deleted now
                local_contact = ImportContact.new
                @total_creations += 1
              else
                @total_updates += 1
              end

              local_contact.assign_attributes(
                ClinikoImporting::Mapper::Contact.build(cliniko_contact)
              )

              local_contact.save!
              import_record.internal_id = local_contact.id
              import_record.last_synced_at = @sync_start_at
              import_record.save!
              log " - Updated: ##{local_contact.id} | Ref ID: #{cliniko_contact.id}"
            else
              # log "Cliniko contact ##{cliniko_contact.id} already imported. SKIPPED"
            end
          end
        end
      end

      @total += contacts.count

      if res['links']['next'].present?
        sleep(5)
        fetch_contacts(res['links']['next'])
      end
    end

    fetch_contacts

    log "Import finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end
