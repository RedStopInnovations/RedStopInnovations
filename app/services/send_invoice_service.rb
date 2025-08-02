class SendInvoiceService
  def call(invoice, sender = nil)
    business = invoice.business
    patient = invoice.patient

    email_template = business.get_communication_template('send_invoice_pdf')
    embed_variables = [
      business, invoice, patient
    ]
    unless invoice.practitioner.nil?
      embed_variables << invoice.practitioner
    end

    email_content = Letter::Renderer.new(patient, email_template).render(embed_variables).content
    email_subject = email_template.email_subject.presence || "Invoice #{invoice.invoice_number} from #{business.name}"

    recipient_email =
      if invoice.invoice_to_contact && invoice.invoice_to_contact.email.present?
        invoice.invoice_to_contact.email
      else
        patient.invoice_to_contacts.where("email <> ''").first&.email
      end

    if recipient_email.blank? && patient.email.present?
      recipient_email = patient.email
    end

    if recipient_email.blank?
      return false
    end

    # Create communication record
    com = business.communications.create!(
      message_type: Communication::TYPE_EMAIL,
      linked_patient_id: patient.id,
      recipient: patient,
      category: 'invoice_send',
      subject: email_subject,
      message: email_content,
      source: invoice,
      direction: Communication::DIRECTION_OUTBOUND
    )

    com_delivery = CommunicationDelivery.create!(
      communication_id: com.id,
      recipient: recipient_email,
      tracking_id: SecureRandom.base58(32),
      last_tried_at: Time.current,
      status: CommunicationDelivery::STATUS_SCHEDULED,
      provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
    )

    InvoiceMailer.invoice_mail_new(
      invoice, recipient_email, email_subject, email_content, sendgrid_delivery_tracking_id: com_delivery.tracking_id
    ).deliver_later
  end
end