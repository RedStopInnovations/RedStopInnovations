# Example: rails healthkit:import_organisation_address business_id=135 csv=tmp/healthkit/organisationaddress.csv
namespace :healthkit do
  task import_organisation_address: :environment do
    @logger = Logger.new("tmp/healthkit_import_organisation_address_log_#{Time.now.to_i}.log")
    class LocalContact < ::ActiveRecord::Base
      self.table_name = 'contacts'
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
    log "Starting import organisation address for business: ##{ @business.id } - #{ @business.name }"

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
        contact_ref_id = healthkit_attrs.fetch 'organisation'

        import_record = HealthkitImporting::ImportRecord.find_or_initialize_by(
          reference_id: contact_ref_id,
          resource_type: 'Contact',
          business_id: @business.id
        )

        if import_record.persisted?
          local_contact = LocalContact.find_by(id: import_record.internal_id)
        end

        if local_contact.nil?
          log "- Contact ref id #{contact_ref_id} is not exist. Skipped."
        else
          if local_contact.latitude? && local_contact.longitude?
            log "- Contact ref id #{contact_ref_id} is geocoded already. Skipped."
          else
            full_address = [
              healthkit_attrs['first'].presence,
              healthkit_attrs['second'].presence,
              healthkit_attrs['city'].presence,
              healthkit_attrs['state'].presence,
              healthkit_attrs['postcode'].presence,
              healthkit_attrs['country'].presence
            ].compact.join(', ')

            geocoding_results = Geocoder.search(full_address)
            if geocoding_results.blank?
              log '- No geocode result. Set address as provided'
              local_contact.address1 = [healthkit_attrs['first'].presence, healthkit_attrs['second'].presence].compact.join(', ')
              local_contact.city = healthkit_attrs['city'].presence
              local_contact.state = healthkit_attrs['state'].presence
              local_contact.postcode = healthkit_attrs['postcode'].presence
              local_contact.country = ISO3166::Country.find_country_by_name(healthkit_attrs['country']).try(:alpha2) || 'AU'
            else
              geocode_result = geocoding_results.first
              address1_cmpts = []
              address2 = nil
              geocode_result.data['address_components'].each do |addr_cmpt|
                if addr_cmpt['types'].include?('street_number') || addr_cmpt['types'].include?('route')
                  address1_cmpts << addr_cmpt['long_name']
                end

                if addr_cmpt['types'].include?('premise')
                  address2 = addr_cmpt['long_name']
                end

                # State
                if addr_cmpt['types'].include?('administrative_area_level_1')
                  local_contact.state = addr_cmpt['short_name']
                end

                # Postcode
                if addr_cmpt['types'].include?('postal_code')
                  local_contact.postcode = addr_cmpt['short_name']
                end

                # City
                if addr_cmpt['types'].include?('locality')
                  local_contact.city = addr_cmpt['short_name']
                end
              end

              formatted_address_cmpts = geocode_result.data['formatted_address'].split(',')

              if formatted_address_cmpts.size == 3
                local_contact.address1 = formatted_address_cmpts[0]
              elsif formatted_address_cmpts.size == 4
                local_contact.address1 = formatted_address_cmpts[1]
              else
                log "Strange result: #{formatted_address_cmpts.join('|')}"
                local_contact.address1 = [healthkit_attrs['first'].presence, healthkit_attrs['second'].presence].compact.join(', ')
                local_contact.city = healthkit_attrs['city']
                local_contact.postcode = healthkit_attrs['postcode']
                local_contact.country = ISO3166::Country.find_country_by_name(healthkit_attrs['country']).try(:alpha2) || 'AU'
              end

              if address2.nil? && geocode_result.data['place_id']
              else
                local_contact.address2 = address2
              end
              coordinates = geocode_result.data.dig 'geometry', 'location'
              local_contact.latitude = coordinates['lat']
              local_contact.longitude = coordinates['lng']
            end

            local_contact.save!
          end

          imported_count += 1
          log "- Progress: #{imported_count}"
          if (imported_count % 100) == 0
            log "Sleeping ... zzZ"
            sleep(3)
          end
        end

      rescue => e
        failed_refs << contact_ref_id
        log "ERROR: #{contact_ref_id} | Message: #{e.message}"
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
