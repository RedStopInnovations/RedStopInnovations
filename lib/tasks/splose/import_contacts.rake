namespace :splose do |args|
  # bin/rails splose:import_contacts business_id=1 api_key=xxx force_update=1
  task import_contacts: :environment do
    @splose_base_url = nil

    def map_contact_attrs(splose_attrs)
      internal_attrs = {}

      internal_attrs[:contact_type] = splose_attrs['type'].presence
      internal_attrs[:title] = splose_attrs['title'].presence
      internal_attrs[:first_name] = splose_attrs['firstName'].presence
      internal_attrs[:last_name] = splose_attrs['lastName'].presence
      internal_attrs[:email] = splose_attrs['email'].presence
      internal_attrs[:business_name] = splose_attrs['name'].presence
      internal_attrs[:company_name] = splose_attrs['companyName'].presence

      internal_attrs[:full_name] = "#{internal_attrs[:first_name]} #{internal_attrs[:last_name]}".strip

      internal_attrs[:address1] = splose_attrs['addressL1'].presence
      internal_attrs[:address2] = splose_attrs['addressL2'].presence
      internal_attrs[:address3] = splose_attrs['addressL3'].presence
      internal_attrs[:city] = splose_attrs['suburb'].presence || splose_attrs['city'].presence
      internal_attrs[:postcode] = splose_attrs['postalCode'].presence
      internal_attrs[:state] = splose_attrs['state'].presence
      internal_attrs[:country] = splose_attrs['country'].presence

      if splose_attrs['phoneNumbers'].present?
        splose_attrs['phoneNumbers'].each do |phone_number|
          if phone_number['type'] == 'Mobile'
            internal_attrs[:mobile] = "#{phone_number['code']}#{phone_number['phoneNumber']}".strip
          end

          if phone_number['type'] == 'Home'
            internal_attrs[:phone] = "#{phone_number['code']}#{phone_number['phoneNumber']}".strip
          end

          if phone_number['type'] == 'Work'
            internal_attrs[:phone] = "#{phone_number['code']}#{phone_number['phoneNumber']}".strip
          end
        end
      end

      if splose_attrs['archived']
        internal_attrs[:archived_at] = splose_attrs['updatedAt']
      else
        internal_attrs[:archived_at] = nil
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
    @splose_base_url = ENV['splose_base_url'].presence

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

    def fetch_contacts(url = '/v1/contacts')
      log "Fetching contacts ... "
      res = fetch_with_retry(url)
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

          if @splose_base_url.present?
            import_record.reference_url = "#{@splose_base_url}/contacts/#{contact_raw_attrs['id']}"
          end

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
        sleep(15)
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
