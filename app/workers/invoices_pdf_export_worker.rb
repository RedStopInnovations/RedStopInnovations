class InvoicesPdfExportWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'data_export', retry: 3

  def perform(export_id)
    export = InvoicesPdfExport.find_by(id: export_id)
    if export
      export.status = InvoicesPdfExport::STATUS_PENDING
      export.save!

      begin
        exporter_options = Export::Invoices::Options.new(export.options)
        exporter = Export::Invoices.new(export.business, exporter_options)

        pdf_paths = []

        # Generate pdfs
        working_dir = Rails.root.join("tmp/invoices_pdf_export_#{export.id}__#{Time.now.to_i}").to_s
        FileUtils.mkdir_p working_dir

        exporter.items_query
          .preload(:patient, :items, :business, :appointment, :practitioner, :patient_case, :invoice_to_contact, :payments)
          .find_each do |invoice|
          pdf_content = WickedPdf.new.pdf_from_string(ActionController::Base.new.render_to_string(
            template: 'pdfs/invoice',
            locals: { invoice: invoice }
          ))

          pdf_file_path = "#{working_dir}/#{invoice.invoice_number}_#{invoice.id}.pdf"
          File.open(pdf_file_path, 'wb') do |file|
            file << pdf_content
          end

          pdf_paths << pdf_file_path
        end

        # Make zip file
        zip_file_name = "invoices_pdf_export_#{export.created_at.utc.strftime('%Y%m%d')}.zip"
        zip_file_path = "#{working_dir}/#{zip_file_name}"

        Zip::File::open(zip_file_path, true) do |zip_file|
          pdf_paths.each do |pdf_path|
            zip_file.add(File.basename(pdf_path), pdf_path)
          end
        end

        # Attach zip file to export instance
        export.zip_file.attach(
          io: File.open(zip_file_path),
          filename: zip_file_name
        )

        export.status = InvoicesPdfExport::STATUS_COMPLETED
        export.save!

        InvoicesPdfExportMailer.export_download_ready_mail(export).deliver_now
        FileUtils.rm_rf(working_dir, secure: true) if File.directory?(working_dir)
      rescue => e
        export.status = InvoicesPdfExport::STATUS_ERROR
        export.save!
        Sentry.capture_exception(e)
      end
    end
  end
end
