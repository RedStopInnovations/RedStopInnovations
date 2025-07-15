class AttendanceProofExportWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'data_export', retry: 3

  def perform(export_id)
    export = AttendanceProofExport.find_by(id: export_id)

    if export
      export.status = AttendanceProofExport::STATUS_PENDING
      export.save!

      begin
        exporter_options = Export::AttendanceProof::Options.new(export.options)
        exporter = Export::AttendanceProof.new(export.business, exporter_options)


        appointments = exporter.items
        attachment_paths = []

        # Generate pdfs
        working_dir = Rails.root.join("tmp/attendance_proof_export_#{export.id}__#{Time.now.to_i}").to_s

        # Make zip file
        zip_file_name = "attendance_proof_export_#{export.created_at.utc.strftime('%Y%m%d')}.zip"
        zip_file_path = "#{working_dir}/#{zip_file_name}"

        FileUtils.mkdir_p working_dir

        Zip::File::open(zip_file_path, true) do |zip_file|

          appointments.each do |appointment|
            appt_folder_name = [
              appointment.start_time.strftime('%Y%b%d'),
              appointment.patient.full_name.parameterize,
              appointment.practitioner.full_name.parameterize,
              "#{appointment.id}"
            ].join('__')

            appointment.attendance_proofs.each do |ap|
              path_in_zip = "#{appt_folder_name}/#{ap.filename}"

              FileUtils.mkdir_p "#{working_dir}/#{appt_folder_name}"
              full_path = "#{working_dir}/#{path_in_zip}"

              File.open(full_path, 'wb') do |file|
                file << ap.download
              end

              zip_file.add(path_in_zip, full_path)
            end
          end

        end

        # Attach zip file to export instance
        export.zip_file.attach(
          io: File.open(zip_file_path),
          filename: zip_file_name
        )

        export.status = AttendanceProofExport::STATUS_COMPLETED
        export.save!

        AttendanceProofExportMailer.export_download_ready_mail(export).deliver_now
        # File.delete(zip_file_path) if File.exist?(zip_file_path)
        FileUtils.rm_rf working_dir
      rescue => e
        export.status = AttendanceProofExport::STATUS_ERROR
        export.save!
        Sentry.capture_exception(e)
      end
    end
  end
end
