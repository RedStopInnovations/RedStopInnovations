class PatientAttachmentExportWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'data_export', retry: 3

  def perform(export_id)
    export = PatientAttachmentExport.find_by(id: export_id)

    if export
      export.status = PatientAttachmentExport::STATUS_PENDING
      export.save!

      start_at = Time.now

      begin
        exporter_options = Export::PatientAttachments::Options.new(export.options)
        exporter = Export::PatientAttachments.new(export.business, exporter_options)

        working_dir = Rails.root.join("tmp/patient_attachments_export_#{export.id}__#{start_at.to_i}").to_s
        logger = Logger.new("log/patient_attachments_export_#{export.id}.log")

        items_count = exporter.items_query.count
        processed_items_count = 0

        logger.info "Export ##{export.id} started #{start_at}"
        logger.info "Items count: #{items_count}. Working dir: #{working_dir}"

        FileUtils.mkdir_p working_dir

        # Make zip file
        zip_file_name = "client_attachments_export_#{export.created_at.utc.strftime('%Y%m%d')}.zip"
        zip_file_path = "#{working_dir}/#{zip_file_name}"

        Zip::File::open(zip_file_path, true) do |zip_file|
          exporter.items_query.find_each do |attachment|
            if attachment.attachment.exists?
              begin
                path_in_zip = "#{attachment.patient.full_name.parameterize(separator: '_')}__#{attachment.patient_id}/#{attachment.id}__#{attachment.attachment.original_filename}"
                zip_file.get_output_stream(path_in_zip) do |io|
                  io.write Paperclip.io_adapters.for(attachment.attachment).read
                end

                processed_items_count += 1

                if processed_items_count % 100 == 0
                  logger.info "Processed #{processed_items_count}/#{items_count} (#{(processed_items_count.to_f/items_count * 100).round(1)}%). Elapsed time: #{((Time.now.to_i - start_at.to_i) / 60.to_f).round(1)} mins"
                end
              rescue Errno::ENOENT => e
                # Ignore file not exists error
                logger.info "Error with attachment ##{attachment.id}"
              end
            end
          end
        end

        logger.info "Zip file has been created"

        logger.info "Attach zip to ActiveStorage"
        # Attach zip file to export instance
        export.zip_file.attach(
          io: File.open(zip_file_path),
          filename: zip_file_name
        )

        export.status = PatientAttachmentExport::STATUS_COMPLETED
        export.save!

        logger.info "Attach zip complete"

        logger.info "Sending notification"
        PatientAttachmentExportMailer.export_download_ready_mail(export).deliver_now
        logger.info "Clean up"
        FileUtils.rm_rf(working_dir, secure: true) if File.directory?(working_dir)
      rescue => e
        logger.info "Error: #{e.message}"
        export.status = PatientAttachmentExport::STATUS_ERROR
        export.save!
        Sentry.capture_exception(e)
      end

      logger.info "Finished at #{Time.now}"
    end
  end
end
