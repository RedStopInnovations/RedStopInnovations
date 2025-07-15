class CreateAttendanceProofExportService
  attr_reader :author, :business, :form_request

  def call(author, form_request)
    @business = author.business
    @author = author
    @form_request = form_request
    export = build_export_record
    export.save!

    AttendanceProofExportWorker.perform_async(export.id)
    export
  end

  private

  def build_export_record
    export = AttendanceProofExport.new
    export.options = form_request.attributes.slice(
      *%i(invoice_id account_statement_id)
    )
    export.description = form_request.description
    export.business_id = business.id
    export.author_id = author.id
    export.status = AttendanceProofExport::STATUS_PENDING

    export
  end
end