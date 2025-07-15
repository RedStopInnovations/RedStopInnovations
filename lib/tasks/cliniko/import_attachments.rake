#bin/rails cliniko:import_attachments business_id=123 api_key=xxx api_shard=au1
namespace :cliniko do |args|
  task import_attachments: :environment do

    def log(what)
      puts "[CLINIKO_IMPORT] #{what}"
    end

    business_id = ENV['business_id']
    api_key = ENV['api_key']
    api_shard = ENV['api_shard']

    if business_id.blank? || api_key.blank?
      raise ArgumentError, "Required agruments is missing!"
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
    log "Start import attachments for business ##{business_id} - #{@business.name}"

    @api_client = ClinikoApi::Client.new(api_key, api_shard)

    @total = 0
    @total_creations = 0
    @total_updates = 0
    @total_skips = 0
    @total_errors = 0

    def fetch_patient_attachments(url = '/patient_attachments')
      log "Fetching attachments ... "
      res = @api_client.call(:get, url, per_page: 100)
      attachments = res['patient_attachments']
      log "Got: #{attachments.count} records."

      attachments.each do |raw_attrs|
        ActiveRecord::Base.transaction do
          cliniko_attachment = ClinikoApi::Resource::PatientAttachment.new
          cliniko_attachment.attributes = raw_attrs

          download_content_url = cliniko_attachment.content_url

          # Find the Cliniko patient
          imported_patient = ClinikoImporting::ImportRecord.find_by(
            business_id: @business.id,
            resource_type: 'Patient',
            reference_id: cliniko_attachment.parse_patient_id
          )

          if !imported_patient
            log "[SKIPPED] Not found imported patient for patient attachment ref ID ##{cliniko_attachment.id}"
            @total_skips +=1
            next
          end

          import_record = ClinikoImporting::ImportRecord.find_or_initialize_by(
            business_id: @business.id,
            reference_id: cliniko_attachment.id,
            resource_type: 'PatientAttachment'
          )

          ActiveRecord::Base.transaction do
            begin
              if import_record.new_record?
                local_attachment = ::PatientAttachment.new(
                  ClinikoImporting::Mapper::PatientAttachment.build(cliniko_attachment)
                )
                file_content = @api_client.call :get, download_content_url

                upload_file = StringIO.new(file_content)
                upload_file.class.class_eval { attr_accessor :original_filename }
                upload_file.original_filename = cliniko_attachment.filename

                local_attachment.attachment = upload_file
                local_attachment.patient_id = imported_patient.internal_id

                if local_attachment.valid?
                  local_attachment.save!(validate: false)

                  import_record.internal_id = local_attachment.id
                  import_record.last_synced_at = @sync_start_at
                  import_record.save!

                  log "[CREATED] Attachment ref ID #{cliniko_attachment.id}. Internal ID ##{local_attachment.id}. Internal patient ID ##{local_attachment.patient_id}"

                  @total_creations += 1
                else
                  log "[SKIPPED] Attachment ref ID #{cliniko_attachment.id} invalid: #{local_attachment.errors.full_messages.join(', ')}"
                  @total_skips +=1
                end

              else
                # TODO: compare with updated_at on local record is better
                if cliniko_attachment.updated_at > import_record.last_synced_at
                  log "Cliniko attachment ##{cliniko_attachment.id} has new update."
                  local_attachment = ::PatientAttachment.find_by(
                    id: import_record.internal_id
                  )
                  if local_attachment.nil? # Synced but deleted later
                    local_attachment = ::PatientAttachment.new
                    @total_creations += 1
                  else
                    @total_updates += 1
                  end

                  local_attachment.assign_attributes(
                    ClinikoImporting::Mapper::PatientAttachment.build(cliniko_attachment)
                  )
                  local_attachment.save!(validate: false)
                  import_record.internal_id = local_attachment.id
                  import_record.last_synced_at = @sync_start_at
                  import_record.save!
                else
                  log "[SKIPPED] Cliniko patient attachment ##{cliniko_attachment.id} is up to date."
                end
              end
            rescue ActiveRecord::RecordInvalid => e
              @total_errors += 1
            end
          end

        end
      end

      @total += attachments.count

      log "Progress: #{@total} records"

      if res['links']['next'].present?
        sleep(5)
        fetch_patient_attachments(res['links']['next'])
      end
    end

    fetch_patient_attachments

    log "Sync finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Skips:     #{@total_skips}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end
