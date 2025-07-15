#rake coreplus:import_patient_attachments business_id=135 dir=
namespace :coreplus do
  task import_patient_attachments: :environment do
    @logger = Logger.new("tmp/coreplus_import_patients_attachments_#{Time.now.to_i}.log")

    def log(what)
      puts what
      @logger.info what
    end

    business_id = ENV['business_id']
    dir_path = ENV['dir']

    if business_id.blank? || dir_path.blank?
      raise ArgumentError, "Business ID or directory path is missing!"
    end

    patients_count = 0
    imported_count = 0
    fails = []

    @business = Business.find(business_id)
    Dir.glob("#{dir_path}/*").each do |f|
      if File.directory?(f) # Patient's directory
        log "-- Folder: #{f}"
        patient_ref_id = f.split('/').last.scan(/\d+/).first

        import_patient_log = CoreplusImporting::ImportRecord.find_by(
          reference_id: patient_ref_id,
          resource_type: 'Patient',
          business_id: @business.id
        )

        if import_patient_log && @business.patients.exists?(
            id: import_patient_log.internal_id
          )
          log "--- Patient ref: #{patient_ref_id} | Internal ID: #{import_patient_log.internal_id}"
          # Import pdf files
          Dir.glob("#{f}/*.pdf").each do |pdf_file|
            begin
              log "--- File: #{pdf_file}"
              file_name = pdf_file.split('/').last
              attachment_ref_id = "#{patient_ref_id}-#{Digest::MD5.hexdigest(file_name)}"

              import_attm_log = CoreplusImporting::ImportRecord.find_by(
                reference_id: attachment_ref_id,
                business_id: @business.id,
                resource_type: 'PatientAttachment'
              )
              if import_attm_log
                log "----- Already imported. Skipped"
              else
                p_attm = ::PatientAttachment.new(
                  patient_id: import_patient_log.internal_id,
                  description: 'Imported from Coreplus',
                  attachment: File.open(pdf_file)
                )

                p_attm.save!(validate: false)

                import_log = CoreplusImporting::ImportRecord.new(
                  business_id: @business.id,
                  reference_id: attachment_ref_id,
                  resource_type: 'PatientAttachment',
                  internal_id: p_attm.id,
                  last_synced_at: Time.current
                )
                import_log.save!(validate: false)
                imported_count += 1
              end
            rescue => e
              log "ERROR: #{e.message}; File: #{pdf_file}; #{e.backtrace.join("\n")}"
              fails << pdf_file
            end
          end
        else
          log "--- Not found patient ref ID: #{patient_ref_id}. Skipped."
        end
      end
    end

    log "Import done!"
    log "Patients count:  #{patients_count}"
    log "Imported: #{imported_count}"
    log "Fails:   #{fails.count}"
    unless fails.empty?
      log "Failed files: [#{fails.join(",")}]"
    end
  end
end
