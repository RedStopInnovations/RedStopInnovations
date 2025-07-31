class SendTreatmentNoteEmailService
  # @param patient ::Patient
  # @param treatment_note Treatment
  # @param form SendEmailForm
  # @param author User
  def call(patient, treatment_note, form, author)
    business = patient.business

    form.emails.each do |recipient_email|
      email_subject = form.email_subject
      email_content = form.email_content

      com = business.communications.create!(
        message_type: Communication::TYPE_EMAIL,
        linked_patient_id: patient.id,
        recipient: patient,
        category: 'treatment_note_send',
        subject: email_subject,
        message: email_content,
        source: treatment_note,
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

      TreatmentNoteMailer.treatment_note_mail(
        treatment_note, recipient_email, email_subject, email_content, sendgrid_delivery_tracking_id: com_delivery.tracking_id
      ).deliver_later
    end
  end
end
