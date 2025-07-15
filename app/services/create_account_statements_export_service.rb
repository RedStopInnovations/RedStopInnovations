class CreateAccountStatementsExportService
  attr_reader :author, :business, :form_request

  def call(author, form_request)
    @business = author.business
    @author = author
    @form_request = form_request
    export = build_export_record
    export.save!

    AccountStatementsExportWorker.perform_async(export.id)
    export
  end

  private

  def build_export_record
    export = AccountStatementsExport.new
    options = form_request.attributes.slice(
      *%i(source_type source_ids start_date end_date payment_status)
    )
    export.options = options
    export.description = form_request.description
    export.business_id = business.id
    export.author_id = author.id
    export.status = AccountStatementsExport::STATUS_PENDING

    export
  end
end
