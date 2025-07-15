#rake coreplus:import_case_notes business_id=135 dir=
namespace :coreplus do
  task import_case_notes: :environment do
    @logger = Logger.new("tmp/coreplus_import_patients_case_notes_#{Time.now.to_i}.log")

    def log(what)
      puts what
      @logger.info what
    end

    business_id = ENV['business_id']
    dir_path = ENV['dir']

    if business_id.blank? || dir_path.blank?
      raise ArgumentError, "Business ID or notes directory path is missing!"
    end

    count = 0
    imported_count = 0
    fails = []

    @business = Business.find(business_id)
    Dir.glob("#{dir_path}/*.html").each do |html_file|
      log "- #{count}: #{html_file}"
      html_file_name = html_file.split('/').last
      pdf_file_name = html_file_name.gsub '.html', '.pdf'
      patient_ref_id = html_file.split('/').last.scan(/\d+/).first
      html_content = File.read html_file
      attachment_ref_id = "#{patient_ref_id}-casenote-#{Digest::MD5.hexdigest(html_file)}"
      begin
        import_patient_log = CoreplusImporting::ImportRecord.find_by(
          reference_id: patient_ref_id,
          resource_type: 'Patient',
          business_id: @business.id
        )

        if import_patient_log && @business.patients.exists?(id: import_patient_log.internal_id)
          log "-- > Patient ID: #{import_patient_log.internal_id}. Ref ID: #{patient_ref_id}"

          import_attm_log = CoreplusImporting::ImportRecord.find_by(
            reference_id: attachment_ref_id,
            business_id: @business.id,
            resource_type: 'PatientAttachment'
          )

          if import_attm_log
            log "---- Already imported. Skipped"
          else
            pdf = WickedPdf.new.pdf_from_string html_content

            p_attm = ::PatientAttachment.new(
              patient_id: import_patient_log.internal_id,
              description: 'Case notes imported from Coreplus',
              attachment: Extensions::FakeFileIo.new(pdf_file_name, pdf)
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
        else
          log "Not found patient ref ID: #{patient_ref_id}. Skipped."
        end
      rescue => e
        log "ERROR: #{e.message}; File: #{html_file}; \n #{e.backtrace.join("\n")}"
        fails << html_file
      end
      count += 1
    end

    log "Import done!"
    log "Scanned:  #{count}"
    log "Imported: #{imported_count}"
    log "Fails:   #{fails.count}"
    unless fails.empty?
      log "Failed files: [#{fails.join(",")}]"
    end
  end
end
