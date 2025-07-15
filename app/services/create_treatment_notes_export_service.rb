class CreateTreatmentNotesExportService
  attr_reader :author, :business, :form_request

  def call(author, form_request)
    @business = author.business
    @author = author
    @form_request = form_request
    export = build_export_record
    export.save!

    TreatmentNotesExportWorker.perform_async(export.id)
    export
  end

  private

  def build_export_record
    export = TreatmentNotesExport.new
    options = form_request.attributes.slice(
      *%i(start_date end_date template_ids status)
    )
    export.options = options
    export.description = form_request.description
    export.business_id = business.id
    export.author_id = author.id
    export.status = TreatmentNotesExport::STATUS_PENDING

    export
  end
end
