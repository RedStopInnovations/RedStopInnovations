class AccountStatementsExportWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'data_export', retry: 3

  def perform(export_id)
    export = AccountStatementsExport.find_by(id: export_id)
    if export
      export.status = AccountStatementsExport::STATUS_PENDING
      export.save!

      begin
        exporter_options = Export::AccountStatements::Options.new(export.options)
        exporter = Export::AccountStatements.new(export.business, exporter_options)

        pdf_paths = []

        # Download pdfs into a temp folder
        working_dir = Rails.root.join("tmp/account_statements_export_#{export.id}__#{Time.now.to_i}").to_s
        FileUtils.mkdir_p working_dir

        exporter.items_query.find_each do |account_statement|
          if account_statement.pdf.file.exists?

            pdf_file_path = "#{working_dir}/#{account_statement.number}__#{account_statement.id}.pdf"
            File.open(pdf_file_path, 'wb') do |file|
              file << account_statement.pdf.file.read
            end

            pdf_paths << pdf_file_path
          end
        end

        # Make zip file
        zip_file_name = "account_statements_export_#{export.created_at.utc.strftime('%Y%m%d')}.zip"
        zip_file_path = "#{working_dir}/#{zip_file_name}"

        Zip::File::open(zip_file_path, true) do |zip_file|
          pdf_paths.each do |pdf_path|
            zip_file.add("statements/#{File.basename(pdf_path)}", pdf_path)
          end
        end

        # Attach zip file to export instance
        export.zip_file.attach(
          io: File.open(zip_file_path),
          filename: zip_file_name
        )

        export.status = AccountStatementsExport::STATUS_COMPLETED
        export.save!

        # @TODO: notify user?
        FileUtils.rm_rf(working_dir, secure: true) if File.directory?(working_dir)
      rescue => e
        export.status = AccountStatementsExport::STATUS_ERROR
        export.save!
        Sentry.capture_exception(e)
      end
    end
  end
end
