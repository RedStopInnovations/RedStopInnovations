# Example: rails healthkit:import_patient_file business_id=135 dir=tmp/healthkit/files
namespace :healthkit do
  task import_patient_file: :environment do
    @logger = Logger.new("tmp/healthkit_import_patient_file_log_#{Time.now.to_i}.log")
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
      raise ArgumentError, "Business ID or path to file is missing!"
    end

    @business = Business.find(business_id)
    log "Starting import client file for business: ##{ @business.id } - #{ @business.name }"

    print "Continue? (Y/n): "
    confirm = STDIN.gets.chomp

    if confirm != 'Y'
      log "Import cancelled!"
      exit
    end

    imported_count = 0
    failed_refs = []

    Dir.glob("#{dir_path}/*").each do |patient_dir|
      if File.directory?(patient_dir)
        log "-- Folder: #{patient_dir}"
        patient_dir_name = patient_dir.split('/')
        patient_ref_id = patient_dir_name.last.scan(/\d+/).first

        Dir.glob("#{patient_dir}/*.{pdf,png,jpg,JPG,gif,doc,docx,xls,xlsx,txt}").each do |file_path|
          log "- Attachment file: #{file_path}"
          file_name = file_path.split('/').last
          attachment_ref_id = "#{patient_ref_id}-file-#{Digest::MD5.hexdigest(file_name)}"

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
              p_attm = ::PatientAttachment.new(
                patient_id: local_patient.id,
                description: 'File imported from HealthKit',
                attachment: File.open(file_path)
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
