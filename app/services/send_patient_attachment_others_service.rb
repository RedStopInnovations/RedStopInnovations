class SendPatientAttachmentOthersService
  # @param business Business
  # @param attachment PatientAttachment
  def call(business, attachment, form)
    contacts = business.contacts.where(id: form.contact_ids)
    patient = attachment.patient
    contacts.each do |contact|
      if contact.email?
        com = business.communications.create!(
          message_type: Communication::TYPE_EMAIL,
          recipient: contact,
          linked_patient_id: patient.id,
          category: 'patient_attachment_send',
          message: form.message,
          source: attachment
        )

        com_delivery = CommunicationDelivery.create!(
          communication_id: com.id,
          recipient: contact.email,
          tracking_id: SecureRandom.base58(32),
          last_tried_at: Time.current,
          status: CommunicationDelivery::STATUS_SCHEDULED,
          provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
        )

        PatientAttachmentMailer.send_to_contact(
          attachment, contact, form.message, sendgrid_delivery_tracking_id: com_delivery.tracking_id
        ).deliver_later
      end
    end

    form.emails.each do |email|
      PatientAttachmentMailer.send_to_email(
        attachment, email, form.message
      ).deliver_later
    end
  end
end
