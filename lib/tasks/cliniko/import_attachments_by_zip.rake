namespace :cliniko do |args|
  task import_attachments_by_zip: :environment do

    class ImportAttachment < ::ActiveRecord::Base
      self.table_name = 'patient_attachments'
    end

    def log(what)
      puts "[CLINIKO_IMPORT] #{what}"
    end

    business_id = ENV['business_id']
    zip_path = ENV['zip']

    if business_id.blank? || zip_path.blank?
      raise ArgumentError, "Required agruments is missing!"
    end

    @business = Business.find(business_id)

    @sync_start_at = Time.current
    log "Start import attachments for business ##{business_id} - #{@business.name}"

    @total = 0
    @total_uploaded = 0
    @total_skipped = 0
    @total_invalid = 0

    ActiveRecord::Base.transaction do
      Zip::File.open(Rails.root.join(zip_path)) do |zipfile|
        zipfile.each do |file|
          if file.file?
            @total += 1
            dir_name, file_name = file.name.split('/', 2)
            log "== Processing #{file_name}"
            log "- Dir name: #{dir_name}"
            log "- File name: #{file_name}"

            patient_reference_id = dir_name.split(' - ').last
            if patient_reference_id && !patient_reference_id.match(/\A[-+]?\d+\z/).nil?
              log "- Patient reference id: #{patient_reference_id}"

              # Check patient existing
              imported_patient_record = ClinikoImporting::ImportRecord.find_by(
                business_id: @business.id,
                resource_type: 'Patient',
                reference_id: patient_reference_id
              )

              if imported_patient_record
                patient_internal_id = imported_patient_record.internal_id
                if ::Patient.with_deleted.where(id: patient_internal_id).exists?
                  log "- Patient internal id: #{imported_patient_record.internal_id}"

                  attachment_reference_id, attachment_file_name = file_name.split(' - ', 2)
                  if attachment_reference_id.present? && attachment_file_name.present?
                    log "- Attachment reference id: #{attachment_reference_id}"
                    log "- Original file name: #{attachment_file_name}"

                    local_patient_attm = ::PatientAttachment.new(
                      patient_id: patient_internal_id
                    )

                    upload_file = StringIO.new(file.get_input_stream.read)
                    upload_file.class.class_eval { attr_accessor :original_filename }
                    upload_file.original_filename = attachment_file_name

                    local_patient_attm.attachment = upload_file

                    if local_patient_attm.valid?
                      local_patient_attm.save

                      ClinikoImporting::ImportRecord.create!(
                        business_id: @business.id,
                        resource_type: 'PatientAttachment',
                        reference_id: attachment_reference_id,
                        internal_id: local_patient_attm.id,
                        last_synced_at: @sync_start_at
                      )

                      @total_uploaded += 1
                    else
                      @total_invalid += 1
                      log "-------------------------- Attachment not valid ->>>>"
                    end
                  end
                end
              else
                log "- Not found patient ##{patient_reference_id} in local db. Skipped."
                @total_skipped += 1
              end
            else
              @total_skipped += 1
            end
          end
        end
      end
    end

    log "Sync finished:"
    log "Total:     #{@total}"
    log "Uploaded:  #{@total_uploaded}"
    log "Skipped:   #{@total_skipped}"
    log "Invalid:   #{@total_invalid}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end
