class TreatmentNotesExportWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'data_export', retry: 3

  def perform(export_id)
    export = TreatmentNotesExport.find_by(id: export_id)
    if export
      export.status = TreatmentNotesExport::STATUS_PENDING
      export.save!

      start_at = Time.now
      logger = Logger.new("log/treatment_notes_export_#{export.id}.log")

      working_dir = Rails.root.join("tmp/treatment_notes_export_#{export.id}__#{start_at.to_i}").to_s

      begin
        exporter_options = Export::TreatmentNotes::Options.new(export.options)
        exporter = Export::TreatmentNotes.new(export.business, exporter_options)


        FileUtils.mkdir_p working_dir

        items_count = exporter.items_query.count
        pdf_generated_items_count = 0

        logger.info "Export ##{export.id} started #{start_at}"
        logger.info "Items count: #{items_count}. Working dir: #{working_dir}"

        pdfs = []
        exporter.items_query
          .preload(:patient, :author, appointment: [practitioner: :user])
          .find_each(batch_size: 200) do |treatment_note|

          pdf_content = WickedPdf.new.pdf_from_string(ActionController::Base.new.render_to_string(
            template: "pdfs/treatments/single",
            locals: {
              treatment: treatment_note,
              patient: treatment_note.patient,
              business: export.business
            }
          ))

          pdf_file_path = "#{working_dir}/#{treatment_note.id}.pdf"
          File.open(pdf_file_path, 'wb') do |file|
            file << pdf_content
          end

          client_folder_name = "#{ActiveStorage::Filename.new(treatment_note.patient.full_name).sanitized}__#{treatment_note.patient.id}"
          pdf_file_name = "#{treatment_note.id}__#{ActiveStorage::Filename.new(treatment_note.name).sanitized}.pdf"
          pdf_file_path_in_zip = "#{client_folder_name}/#{pdf_file_name}"

          pdfs << {
            path: pdf_file_path,
            path_in_zip: pdf_file_path_in_zip
          }

          pdf_generated_items_count += 1

          if pdf_generated_items_count % 100 == 0
            logger.info "PDF generated #{pdf_generated_items_count}/#{items_count} (#{(pdf_generated_items_count.to_f/items_count * 100).round(1)}%). Elapsed time: #{((Time.now.to_i - start_at.to_i) / 60.to_f).round(1)} mins"
          end
        end

        logger.info "All PDF generated. Elapsed time: #{((Time.now.to_i - start_at.to_i) / 60.to_f).round(1)} mins"
        logger.info "Start making zip"

        # Make zip file
        zip_file_name = "treatment_notes_export_#{export.created_at.utc.strftime('%Y%m%d')}.zip"
        zip_file_path = "#{working_dir}/#{zip_file_name}"

        Zip::File.open(zip_file_path, true) do |zip_file|
          pdfs.each do |pdf|
            zip_file.add(pdf[:path_in_zip], pdf[:path])
          end
        end

        logger.info "zip has been created"

        # Attach zip file to export instance
        logger.info "Attach zip to ActiveStorage"
        export.zip_file.attach(
          io: File.open(zip_file_path),
          filename: zip_file_name
        )

        export.status = TreatmentNotesExport::STATUS_COMPLETED
        export.save!
      rescue => e
        export.status = TreatmentNotesExport::STATUS_ERROR
        export.save!
        logger.error e.message
        Sentry.capture_exception(e)
      ensure
        logger.info "Export finished. Elapsed time: #{((Time.now.to_i - start_at.to_i) / 60.to_f).round(1)} mins"
        FileUtils.rm_rf(working_dir, secure: true) if File.directory?(working_dir)
      end
    end
  end
end
