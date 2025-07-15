namespace :splose do |args|
  # bin/rails splose:import_contacts business_id=1 api_key=xxx force_update=1
  task import_contacts: :environment do
    def map_contact_attrs(splose_attrs)
      internal_attrs = {}

      internal_attrs[:title] = splose_attrs['title'].presence
      internal_attrs[:first_name] = splose_attrs['firstName'].presence
      internal_attrs[:last_name] = splose_attrs['lastName'].presence
      internal_attrs[:email] = splose_attrs['email'].presence
      internal_attrs[:business_name] = splose_attrs['name'].presence
      internal_attrs[:company_name] = splose_attrs['companyName'].presence

      internal_attrs[:full_name] = "#{internal_attrs[:first_name]} #{internal_attrs[:last_name]}".strip

      internal_attrs[:address1] = splose_attrs['addressL1'].presence
      internal_attrs[:address2] = splose_attrs['addressL2'].presence
      internal_attrs[:city] = splose_attrs['city'].presence
      internal_attrs[:postcode] = splose_attrs['postalCode'].presence
      internal_attrs[:state] = splose_attrs['state'].presence
      internal_attrs[:country] = splose_attrs['country'].presence

      if splose_attrs['phoneNumbers'].present?
        splose_attrs['phoneNumbers'].each do |phone_number|
          if phone_number['type'] == 'Mobile'
            internal_attrs[:mobile] = phone_number['phoneNumber']
          end
          if phone_number['type'] == 'Home'
            internal_attrs[:phone] = phone_number['phoneNumber']
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

    class ImportContact < ::ActiveRecord::Base
      self.table_name = 'contacts'
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
    @total_creations = 0
    @total_updates = 0

    def fetch_contacts(url = '/v1/contacts')
      log "Fetching contacts ... "
      res = @api_client.call(:get, url)
      contacts = res['data'] || []
      log "Got: #{contacts.count} records."

      contacts.each do |contact_raw_attrs|
        ActiveRecord::Base.transaction do
          contact_raw_attrs

          import_record = SploseImportRecord.find_or_initialize_by(
            business_id: @business.id,
            reference_id: contact_raw_attrs['id'],
            resource_type: 'Contact'
          )

          if import_record.new_record?
            local_contact = ImportContact.new map_contact_attrs(contact_raw_attrs)

            local_contact.business_id = @business.id
            local_contact.save!

            import_record.internal_id = local_contact.id
            import_record.last_synced_at = @sync_start_at
            import_record.save!
            log " - Created: ##{local_contact.id} | Ref ID: #{contact_raw_attrs['id']}"
            @total_creations += 1
          else
            # TODO: compare with updated_at on local record is better
            if @force_update || Time.parse(contact_raw_attrs['updatedAt']) > import_record.last_synced_at
              log "Contact ##{contact_raw_attrs['id']} has new update."
              local_contact = ImportContact.find_by(
                id: import_record.internal_id
              )
              if local_contact.nil? # Already synced before but deleted now
                local_contact = ImportContact.new
                @total_creations += 1
              else
                @total_updates += 1
              end

              local_contact.assign_attributes map_contact_attrs(contact_raw_attrs)

              local_contact.save!
              import_record.internal_id = local_contact.id
              import_record.last_synced_at = @sync_start_at
              import_record.save!
              log " - Updated: ##{local_contact.id} | Ref ID: #{contact_raw_attrs['id']}"
            else
              # log "Contact ##{contact_raw_attrs['id']} already imported. SKIPPED"
            end
          end
        end
      end

      @total += contacts.count

      if res['links']['nextPage'].present?
        log "Next page found. Fetching more contacts ..."
        sleep(30)
        fetch_contacts(res['links']['nextPage'])
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
