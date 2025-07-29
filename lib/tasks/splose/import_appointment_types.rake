namespace :splose do |args|
  # bin/rails splose:import_appointment_types business_id=1 force_update=1 api_key=xxx
  task import_appointment_types: :environment do
    def map_billable_item_attrs(splose_attrs)
      internal_attrs = {}

      internal_attrs[:name] = splose_attrs['name'].presence
      internal_attrs[:description] = splose_attrs['description'].presence
      internal_attrs[:item_number] = splose_attrs['code'].presence
      internal_attrs[:price] = splose_attrs['pricing'].presence
      internal_attrs[:created_at] = Time.parse(splose_attrs['createdAt']) if splose_attrs['createdAt'].present?
      internal_attrs[:updated_at] = Time.parse(splose_attrs['updatedAt']) if splose_attrs['updatedAt'].present?

      internal_attrs
    end

    def map_appointment_type_attrs(splose_attrs)
      internal_attrs = {}

      internal_attrs[:name] = splose_attrs['name'].presence
      internal_attrs[:description] = splose_attrs['description'].presence
      internal_attrs[:duration] = splose_attrs['duration'].presence
      internal_attrs[:item_number] = splose_attrs['code'].presence
      internal_attrs[:price] = splose_attrs['pricing'].presence
      internal_attrs[:created_at] = Time.parse(splose_attrs['createdAt']) if splose_attrs['createdAt'].present?
      internal_attrs[:updated_at] = Time.parse(splose_attrs['updatedAt']) if splose_attrs['updatedAt'].present?

      internal_attrs[:availability_type_id] = AvailabilityType::TYPE_HOME_VISIT_ID

      internal_attrs
    end

    class SploseImportRecord < ActiveRecord::Base
      self.table_name = 'splose_records'
    end

    class ImportBillableItem < ::ActiveRecord::Base
      self.table_name = 'billable_items'
    end

    class ImportAppointmentType < ::ActiveRecord::Base
      self.table_name = 'appointment_types'
    end

    def log(what)
      puts what
    end

    business_id = ENV['business_id']
    api_key = ENV['api_key']
    @force_update = ENV['force_update'] == '1' || ENV['force_update'] == 'true'

    if business_id.blank? || api_key.blank?
      raise ArgumentError, "Business ID or API key is missing!"
    end

    @business = Business.find(business_id)

    log "Business to processed: ##{@business.name} | Users: #{@business.users.count} | Appointment Types: #{@business.appointment_types.count} | Billable Items: #{@business.billable_items.count}"

    @sync_start_at = Time.current
    log "Import starting: #{@sync_start_at.iso8601}. Business ##{business_id} - #{@business.name}"

    @api_client = SploseApi::Client.new(api_key)

    @total = 0
    @total_creations = 0
    @total_updates = 0
    @total_skipped = 0

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

    def fetch_appointment_types(url = '/v1/services')
      log "Fetching services ... "
      res = fetch_with_retry(url)
      services = res['data'] || []
      log "Got: #{services.count} records."

      services.each do |service_raw_attrs|
        ActiveRecord::Base.transaction do
          # First, handle BillableItem import
          billable_item_import_record = SploseImportRecord.find_or_initialize_by(
            business_id: @business.id,
            reference_id: service_raw_attrs['id'],
            resource_type: 'BillableItem'
          )

          local_billable_item = nil
          if billable_item_import_record.new_record?
            local_billable_item = ImportBillableItem.new map_billable_item_attrs(service_raw_attrs)
            local_billable_item.business_id = @business.id
            local_billable_item.save!(validate: false)

            billable_item_import_record.internal_id = local_billable_item.id
            billable_item_import_record.last_synced_at = @sync_start_at
            billable_item_import_record.save!
            log " - Created BillableItem: ##{local_billable_item.id} | Ref ID: #{service_raw_attrs['id']} | Name: #{local_billable_item.name}"
          else
            # Check if billable item needs update
            if @force_update || Time.parse(service_raw_attrs['updatedAt']) > billable_item_import_record.last_synced_at
              local_billable_item = ImportBillableItem.find_by(
                id: billable_item_import_record.internal_id
              )
              if local_billable_item.nil? # Already synced before but deleted now
                local_billable_item = ImportBillableItem.new
                local_billable_item.business_id = @business.id
              end

              local_billable_item.assign_attributes map_billable_item_attrs(service_raw_attrs)
              local_billable_item.save!(validate: false)
              billable_item_import_record.internal_id = local_billable_item.id
              billable_item_import_record.last_synced_at = @sync_start_at
              billable_item_import_record.save!
              log " - Updated BillableItem: ##{local_billable_item.id} | Ref ID: #{service_raw_attrs['id']} | Name: #{local_billable_item.name}"
            else
              # Get existing billable item
              local_billable_item = ImportBillableItem.find_by(
                id: billable_item_import_record.internal_id
              )
            end
          end

          # Skip if billable item creation/retrieval failed
          unless local_billable_item
            log " - SKIPPED Service ##{service_raw_attrs['id']}: BillableItem creation failed"
            @total_skipped += 1
            next
          end

          # Now handle AppointmentType import
          appointment_type_import_record = SploseImportRecord.find_or_initialize_by(
            business_id: @business.id,
            reference_id: service_raw_attrs['id'],
            resource_type: 'AppointmentType'
          )

          if appointment_type_import_record.new_record?
            local_appointment_type = ImportAppointmentType.new map_appointment_type_attrs(service_raw_attrs)
            local_appointment_type.business_id = @business.id
            local_appointment_type.save!(validate: false)

            # Link the appointment type to the billable item via many-to-many relationship
            ActiveRecord::Base.connection.execute(
              "INSERT INTO appointment_types_billable_items (appointment_type_id, billable_item_id) VALUES (#{local_appointment_type.id}, #{local_billable_item.id})"
            )

            appointment_type_import_record.internal_id = local_appointment_type.id
            appointment_type_import_record.last_synced_at = @sync_start_at
            appointment_type_import_record.save!
            log " - Created AppointmentType: ##{local_appointment_type.id} | Ref ID: #{service_raw_attrs['id']} | Name: #{local_appointment_type.name}"
            @total_creations += 1
          else
            # Check if appointment type needs update
            if @force_update || Time.parse(service_raw_attrs['updatedAt']) > appointment_type_import_record.last_synced_at
              log "AppointmentType ##{service_raw_attrs['id']} has new update."
              local_appointment_type = ImportAppointmentType.find_by(
                id: appointment_type_import_record.internal_id
              )
              if local_appointment_type.nil? # Already synced before but deleted now
                local_appointment_type = ImportAppointmentType.new
                local_appointment_type.business_id = @business.id
                @total_creations += 1
              else
                @total_updates += 1
              end

              local_appointment_type.assign_attributes map_appointment_type_attrs(service_raw_attrs)
              local_appointment_type.save!(validate: false)

              # Update the many-to-many relationship - first remove existing, then add new
              ActiveRecord::Base.connection.execute(
                "DELETE FROM appointment_types_billable_items WHERE appointment_type_id = #{local_appointment_type.id}"
              )
              ActiveRecord::Base.connection.execute(
                "INSERT INTO appointment_types_billable_items (appointment_type_id, billable_item_id) VALUES (#{local_appointment_type.id}, #{local_billable_item.id})"
              )

              appointment_type_import_record.internal_id = local_appointment_type.id
              appointment_type_import_record.last_synced_at = @sync_start_at
              appointment_type_import_record.save!
              log " - Updated AppointmentType: ##{local_appointment_type.id} | Ref ID: #{service_raw_attrs['id']} | Name: #{local_appointment_type.name}"
            else
              # log "AppointmentType ##{service_raw_attrs['id']} already imported. SKIPPED"
            end
          end
        end
      end

      @total += services.count

      if res['links']['nextPage'].present?
        log "Next page found. Fetching more services ..."
        sleep(15)
        fetch_appointment_types(res['links']['nextPage'])
      end
    end

    fetch_appointment_types

    log "Import finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Skipped:   #{@total_skipped}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end