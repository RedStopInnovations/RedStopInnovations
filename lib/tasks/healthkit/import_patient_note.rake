# Example: rails healthkit:import_patient_note business_id=135 dir=tmp/healthkit/notes
namespace :healthkit do
  task import_patient_note: :environment do
    @logger = Logger.new("tmp/healthkit_import_patient_note_log_#{Time.now.to_i}.log")
    class LocalPatient < ::ActiveRecord::Base
      self.table_name = 'patients'
    end

    def log(what)
      puts what
      @logger.info what
    end

    business_id = ENV['business_id']
    dir_path = ENV['dir']

    if business_id.blank? || dir_path.blank?
      raise ArgumentError, "Business ID or path to notes is missing!"
    end

    @business = Business.find(business_id)
    log "Starting import client notes for business: ##{ @business.id } - #{ @business.name }"

    print "Continue? (Y/n): "
    confirm = STDIN.gets.chomp

    if confirm != 'Y'
      log "Import cancelled!"
      exit
    end

    imported_count = 0
    failed_refs = []

    Dir.glob("#{Rails.root.join(dir_path).to_s}/*.html").each do |html_file_path|
      log "- File: #{html_file_path}"
      html_file_name = html_file_path.split('/').last
      patient_ref_id = html_file_name.split('/').last.scan(/\d+/).first
      html_content = File.read html_file_path
      attachment_ref_id = "#{patient_ref_id}-note-#{Digest::MD5.hexdigest(html_file_name)}"

      import_patient_record = HealthkitImporting::ImportRecord.find_or_initialize_by(
        reference_id: patient_ref_id,
        resource_type: 'Patient',
        business_id: @business.id
      )

      import_attm_record = HealthkitImporting::ImportRecord.find_by(
        reference_id: attachment_ref_id,
        business_id: @business.id,
        resource_type: 'PatientAttachment'
      )

      if import_attm_record
        log "-- Already imported. Skipped"
      else
        if import_patient_record.persisted?
          local_patient = LocalPatient.find_by(id: import_patient_record.internal_id)
        end

        if local_patient.nil?
          log "- Patient ref id #{patient_ref_id} is not imported. Skipped."
        else
          pdf = WickedPdf.new.pdf_from_string html_content
          pdf_file_name = html_file_name.gsub '.html', '.pdf'

          p_attm = ::PatientAttachment.new(
            patient_id: local_patient.id,
            description: 'Note imported from HealthKit',
            attachment: Extensions::FakeFileIo.new(pdf_file_name, pdf)
          )

          p_attm.save!(validate: false)

          import_attm_record = HealthkitImporting::ImportRecord.new(
            business_id: @business.id,
            reference_id: attachment_ref_id,
            resource_type: 'PatientAttachment',
            internal_id: p_attm.id,
            last_synced_at: Time.current
          )
          import_attm_record.save!(validate: false)
          log "- Attachment created. Local patient ID: #{local_patient.id}"
          imported_count += 1
          log "- Progress: #{imported_count}"
        end
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
