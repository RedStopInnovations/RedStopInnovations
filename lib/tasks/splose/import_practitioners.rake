namespace :splose do |args|
  # bin/rails splose:import_practitioners business_id=1 force_update=1 api_key=xxx
  task import_practitioners: :environment do
    @splose_base_url = nil

    def map_splose_role_to_user_role(splose_role_name)
      case splose_role_name&.downcase&.strip
      when 'practitioner'
        User::PRACTITIONER_ROLE
      when 'receptionist'
        User::RECEPTIONIST_ROLE
      when 'practice manager'
        User::ADMINISTRATOR_ROLE
      when 'practitioner admin'
        User::ADMINISTRATOR_ROLE
      else
        User::PRACTITIONER_ROLE # Default for any other roles
      end
    end

    def map_practitioner_attrs(splose_attrs)
      internal_attrs = {}

      # Map practitioner specific attributes
      internal_attrs[:profession] = splose_attrs['profession'].presence
      internal_attrs[:first_name] = splose_attrs['firstname'].presence
      internal_attrs[:last_name] = splose_attrs['lastname'].presence
      internal_attrs[:full_name] = "#{internal_attrs[:first_name]} #{internal_attrs[:last_name]}".strip
      internal_attrs[:active] = splose_attrs['isActive'].present? ? splose_attrs['isActive'] : true
      internal_attrs[:allow_online_bookings] = splose_attrs['onlineBooking']

      # Map provider numbers from SPlose format to our format
      if splose_attrs['providerNumbers'].present?
        internal_attrs[:provider_numbers] = splose_attrs['providerNumbers'].map do |provider_num|
          {
            'type' => provider_num['type'],
            'number' => provider_num['number']
          }
        end
      end

      internal_attrs[:created_at] = Time.parse(splose_attrs['createdAt']) if splose_attrs['createdAt'].present?
      internal_attrs[:updated_at] = Time.parse(splose_attrs['updatedAt']) if splose_attrs['updatedAt'].present?

      internal_attrs
    end

    def map_user_attrs(splose_attrs)
      internal_attrs = {}

      internal_attrs[:first_name] = splose_attrs['firstname'].presence
      internal_attrs[:last_name] = splose_attrs['lastname'].presence
      internal_attrs[:full_name] = "#{internal_attrs[:first_name]} #{internal_attrs[:last_name]}".strip
      internal_attrs[:email] = splose_attrs['email'].presence
      internal_attrs[:timezone] = splose_attrs['timezone'].presence || 'Australia/Brisbane'
      internal_attrs[:active] = splose_attrs['isActive'].present? ? splose_attrs['isActive'] : true
      internal_attrs[:is_practitioner] = true

      # Map roleName from SPlose to local User roles using mapping function
      internal_attrs[:role] = map_splose_role_to_user_role(splose_attrs['roleName'])

      # Generate a secure random password for new users
      # They will need to reset their password on first login
      internal_attrs[:password] = SecureRandom.alphanumeric(12) + '1!' # Ensure strong password requirements
      internal_attrs[:password_confirmation] = internal_attrs[:password]

      internal_attrs[:created_at] = Time.parse(splose_attrs['createdAt']) if splose_attrs['createdAt'].present?
      internal_attrs[:updated_at] = Time.parse(splose_attrs['updatedAt']) if splose_attrs['updatedAt'].present?

      internal_attrs
    end

    class ImportUser < ::ActiveRecord::Base
      self.table_name = 'users'
    end

    class ImportPractitioner < ::ActiveRecord::Base
      self.table_name = 'practitioners'
    end

    def log(what)
      puts what
    end

    business_id = ENV['business_id']
    api_key = ENV['api_key']
    @force_update = ENV['force_update'] == '1' || ENV['force_update'] == 'true'
    @splose_base_url = ENV['splose_base_url'].presence

    if business_id.blank? || api_key.blank?
      raise ArgumentError, "Business ID or API key is missing!"
    end

    @business = Business.find(business_id)

    log "Business to processed: ##{@business.name} | Users: #{@business.users.count} | Practitioners: #{@business.practitioners.count}"

    @sync_start_at = Time.current
    log "Import starting: #{@sync_start_at.iso8601}. Business ##{business_id} - #{@business.name}"

    @api_client = SploseApi::Client.new(api_key)

    @total = 0
    @total_creations = 0
    @total_updates = 0
    @total_errors = 0

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

    def fetch_practitioners(url = '/v1/practitioners?include_archived=true')
      log "Fetching practitioners ... "
      res = fetch_with_retry(url)
      practitioners = res['data'] || []
      log "Got: #{practitioners.count} records."

      practitioners.each do |practitioner_raw_attrs|
        ActiveRecord::Base.transaction do
          begin
            import_record = SploseRecord.find_or_initialize_by(
              business_id: @business.id,
              reference_id: practitioner_raw_attrs['id'],
              resource_type: 'Practitioner'
            )

            if @splose_base_url.present?
              import_record.reference_url = "#{@splose_base_url}/practitioners/#{practitioner_raw_attrs['id']}"
            end

            # Skip archived/deleted practitioners unless force_update is enabled
            if practitioner_raw_attrs['archived'] == true || practitioner_raw_attrs['deletedAt'].present?
              if import_record.persisted? && @force_update
                # Mark as inactive but don't delete
                if import_record.internal_id.present?
                  local_practitioner = ImportPractitioner.find_by(id: import_record.internal_id)
                  local_user = ImportUser.find_by(id: local_practitioner&.user_id)

                  if local_practitioner
                    local_practitioner.update!(active: false)
                    log " - Archived: Practitioner ##{local_practitioner.id} | Ref ID: #{practitioner_raw_attrs['id']}"
                  end

                  if local_user
                    local_user.update!(active: false)
                    log " - Archived: User ##{local_user.id} | Ref ID: #{practitioner_raw_attrs['id']}"
                  end
                end
              end
              next
            end

            if import_record.new_record?
              # Create new user first
              user_attrs = map_user_attrs(practitioner_raw_attrs)
              user_attrs[:business_id] = @business.id

              # Check if user with this email already exists in this business
              existing_user = ImportUser.find_by(email: user_attrs[:email], business_id: @business.id)

              if existing_user
                local_user = existing_user
                log " - Found existing user: ##{local_user.id} | Email: #{local_user.email}"
              else
                local_user = ImportUser.new(user_attrs)
                local_user.save!
                log " - Created user: ##{local_user.id} | Email: #{local_user.email} | Ref ID: #{practitioner_raw_attrs['id']}"
              end

              # Create practitioner linked to user
              practitioner_attrs = map_practitioner_attrs(practitioner_raw_attrs)
              practitioner_attrs[:business_id] = @business.id
              practitioner_attrs[:user_id] = local_user.id

              local_practitioner = ImportPractitioner.new(practitioner_attrs)
              local_practitioner.save!

              import_record.internal_id = local_practitioner.id
              import_record.last_synced_at = @sync_start_at
              import_record.save!

              log " - Created practitioner: ##{local_practitioner.id} | User ID: #{local_user.id} | Ref ID: #{practitioner_raw_attrs['id']}"
              @total_creations += 1
            else
              # Update existing practitioner
              if @force_update || Time.parse(practitioner_raw_attrs['updatedAt']) > import_record.last_synced_at
                local_practitioner = ImportPractitioner.find_by(id: import_record.internal_id)

                if local_practitioner.nil?
                  log " - Practitioner record missing for import record ##{import_record.id}, recreating..."

                  # Find or create user
                  user_attrs = map_user_attrs(practitioner_raw_attrs)
                  user_attrs[:business_id] = @business.id

                  existing_user = ImportUser.find_by(email: user_attrs[:email], business_id: @business.id)
                  if existing_user
                    local_user = existing_user
                  else
                    local_user = ImportUser.new(user_attrs)
                    local_user.save!
                  end

                  # Create new practitioner
                  practitioner_attrs = map_practitioner_attrs(practitioner_raw_attrs)
                  practitioner_attrs[:business_id] = @business.id
                  practitioner_attrs[:user_id] = local_user.id

                  local_practitioner = ImportPractitioner.new(practitioner_attrs)
                  local_practitioner.save!

                  @total_creations += 1
                else
                  # Update existing practitioner
                  local_user = ImportUser.find_by(id: local_practitioner.user_id)

                  if local_user
                    user_attrs = map_user_attrs(practitioner_raw_attrs)
                    user_attrs.delete(:password) # Don't update password on existing users
                    user_attrs.delete(:password_confirmation)

                    local_user.assign_attributes(user_attrs)
                    local_user.save!
                  end

                  practitioner_attrs = map_practitioner_attrs(practitioner_raw_attrs)
                  local_practitioner.assign_attributes(practitioner_attrs)
                  local_practitioner.save!

                  @total_updates += 1
                end

                import_record.internal_id = local_practitioner.id
                import_record.last_synced_at = @sync_start_at
                import_record.save!

                log " - Updated practitioner: ##{local_practitioner.id} | User ID: #{local_practitioner.user_id} | Ref ID: #{practitioner_raw_attrs['id']}"
              end
            end

          rescue => e
            @total_errors += 1
            log " - ERROR processing practitioner ID #{practitioner_raw_attrs['id']}: #{e.message}"
            log "   Attrs: #{practitioner_raw_attrs.inspect}"
            raise e if ENV['fail_on_error'] == '1'
          end
        end
      end

      @total += practitioners.count

      if res['links'] && res['links']['nextPage'].present?
        log "Next page found. Fetching more practitioners ..."
        sleep(15)
        fetch_practitioners(res['links']['nextPage'])
      end
    end

    fetch_practitioners

    log "Import finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Errors:    #{@total_errors}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end
