class CreatePatientBulkArchiveRequestService
  attr_reader :author, :business, :form_request

  def call(author, form_request)
    @business = author.business
    @author = author
    @form_request = form_request

    request = build_record
    request.save!

    PatientBulkArchiveRequestWorker.perform_async(request.id)
    request
  end

  private

  def build_record
    request = PatientBulkArchiveRequest.new
    filters = form_request.attributes.slice(
      *%i(
        contact_id create_date_from create_date_to no_appointment_period no_invoice_period no_treatment_note_period
      )
    ).delete_if { |k, v| !v.present? }

    request.filters = filters
    request.description = form_request.description
    request.business_id = business.id
    request.author_id = author.id
    request.status = PatientBulkArchiveRequest::STATUS_PENDING

    request
  end
end