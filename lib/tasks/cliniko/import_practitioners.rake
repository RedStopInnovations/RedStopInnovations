namespace :cliniko do |args|
  task import_practitioners: :environment do

    class ImportUser < ::ActiveRecord::Base
      self.table_name = 'users'
    end

    class ImportPractitioner < ::ActiveRecord::Base
      self.table_name = 'practitioners'
    end

    def log(what)
      puts "[CLINIKO_IMPORT] #{what}"
    end

    business_id = ENV['business_id']
    api_key = ENV['api_key']

    if business_id.blank? || api_key.blank?
      raise ArgumentError, "Required agruments is missing!"
    end

    @business = Business.find(business_id)

    @sync_start_at = Time.current
    log "Start import practitioners for business ##{business_id} - #{@business.name}"

    @api_client = ClinikoApi::Client.new(api_key)
    @total = 0
    @total_creations = 0
    @total_updates = 0
    @total_skips = 0

    ActiveRecord::Base.transaction do
      def fetch_practitioners(url = '/practitioners')
        log "Fetching practitioners ... "
        res = @api_client.call(:get, url, per_page: 100)
        practitioners = res['practitioners']
        log "Got #{practitioners.count} records."

        practitioners.each do |raw_attrs|
          cliniko_practitioner = ClinikoApi::Resource::Practitioner.new
          cliniko_practitioner.attributes = raw_attrs

          import_practitioner_record = ClinikoImporting::ImportRecord.find_or_initialize_by(
            business_id: @business.id,
            reference_id: cliniko_practitioner.id,
            resource_type: 'Practitioner'
          )

          # Get user info
          user_attrs = @api_client.call(:get, cliniko_practitioner.user['links']['self'])

          cliniko_user = ClinikoApi::Resource::User.new
          cliniko_user.attributes = user_attrs
          if import_practitioner_record.new_record?
            exists_user = User.find_by(email: cliniko_user.email)
            if exists_user.nil?

              local_pract = ImportPractitioner.new(
                ClinikoImporting::Mapper::Practitioner.build(cliniko_practitioner)
              )
              full_name = [local_pract.first_name, local_pract.last_name].compact.join(' ').strip
              slug = full_name.parameterize

              if ImportPractitioner.where(slug: slug).exists?
                slug_padding = ImportPractitioner.where(slug: slug_candidate).count + 1
                slug << "-#{slug_padding}"
              end

              local_pract.assign_attributes(
                business_id: @business.id,
                active: true,
                full_name: full_name,
                slug: slug
              )

              # Build local user
              local_user = ImportUser.new
              local_user.assign_attributes(
                business_id: @business.id,
                role: User::PRACTITIONER_ROLE,
                is_practitioner: true,
                email: cliniko_user.email,
                first_name: cliniko_user.first_name,
                last_name: cliniko_user.last_name,
                full_name: full_name,
                timezone: cliniko_user.time_zone,
                created_at: cliniko_user.created_at,
                updated_at: cliniko_user.updated_at
              )
              local_user.save!
              local_pract.user_id = local_user.id
              local_pract.save!

              import_practitioner_record.internal_id = local_pract.id
              import_practitioner_record.last_synced_at = @sync_start_at
              import_practitioner_record.save!
              @total_creations += 1
            else
              if exists_user.business_id == @business.id
                import_practitioner_record.internal_id = exists_user.practitioner.id
                import_practitioner_record.last_synced_at = @sync_start_at
                import_practitioner_record.save!
              else
                log "Skip due to email '#{cliniko_user.email}' is belong to another business"
                @total_skips += 1
                next
              end
            end
          else
            log "#{cliniko_user.email} is already imported"
            @total_updates += 1
          end
        end

        @total += practitioners.count

        if res['links']['next'].present?
          fetch_practitioners(res['links']['next'])
        end
      end

      fetch_practitioners
    end

    log "Sync finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Time:      #{Time.current - @sync_start_at} secs"
  end
end
