class UpdatePractitionerDocumentService
  # @param practitioner Practitioner
  # @param form UpdatePractitionerDocumentForm
  def call(practitioner, form)
    document = practitioner.documents.where(type: form.type).first

    if document
      if form.file
        document.document = form.file
      end
      document.expiry_date = form.expiry_date.presence
      document.save!(validate: false)
    else
      if form.file.present?
        document = practitioner.documents.new(type: form.type)
        document.document = form.file
        document.expiry_date = form.expiry_date.presence
        document.save!(validate: false)
      end
    end
  end
end