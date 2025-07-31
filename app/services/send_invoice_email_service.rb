class SendInvoiceEmailService
  # @param invoice ::Invoice
  # @param form SendEmailForm
  # @param author User
  def call(invoice, form, author)
    patient = invoice.patient
    business = patient.business

    form.emails.each do |recipient_email|
      email_subject = form.email_subject
      email_content = form.email_content

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

    invoice.update(
      last_send_at: Time.current
    )
  end
end
