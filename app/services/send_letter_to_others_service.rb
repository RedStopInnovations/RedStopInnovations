class SendLetterToOthersService
  class Exception < StandardError; end

  # @param patient_letter PatientLetter
  # @param sender User
  # @param form SendLetterToOthersForm
  def call(patient_letter, sender, form)
    @patient_letter = patient_letter
    patient = patient_letter.patient
    business = patient.business
    contacts = business.contacts.where("email <> ''").where(id: form.contact_ids)

    # Send to contacts
    contacts.each do |contact|
      if contact.email?
        com = business.communications.create!(
          message_type: Communication::TYPE_EMAIL,
          recipient: contact,
          linked_patient_id: patient.id,
          category: 'letter_send',
          message: @patient_letter.content,
          source: @patient_letter,
          direction: Communication::DIRECTION_OUTBOUND
        )

        com_delivery = CommunicationDelivery.create!(
          communication_id: com.id,
          recipient: contact.email,
          tracking_id: SecureRandom.base58(32),
          last_tried_at: Time.current,
          status: CommunicationDelivery::STATUS_SCHEDULED,
          provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
        )

        if form.send_format == 'email'
          PatientLetterMailer.send_as_email_to_email(
            @patient_letter,
            sender,
            contact.email,
            form.email_subject,
            sendgrid_delivery_tracking_id: com_delivery.tracking_id
          ).deliver_later
        elsif form.send_format == 'attachment'
          PatientLetterMailer.send_as_attachment_to_email(
            @patient_letter,
            sender,
            contact.email,
            form.email_subject,
            form.email_content,
            sendgrid_delivery_tracking_id: com_delivery.tracking_id
          ).deliver_later
        end
      end
    end

    # Send to additional emails
    form.emails.each do |recipient_email|
        if form.send_format == 'email'
          PatientLetterMailer.send_as_email_to_email(
            @patient_letter,
            sender,
            recipient_email,
            form.email_subject,
          ).deliver_later
        elsif form.send_format == 'attachment'
          PatientLetterMailer.send_as_attachment_to_email(
            @patient_letter,
            sender,
            recipient_email,
            form.email_subject,
            form.email_content,
          ).deliver_later
        end
    end
  end
end
