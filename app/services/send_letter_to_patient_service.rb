class SendLetterToPatientService
  class Exception < StandardError; end

  # @param patient_letter PatientLetter
  # @param sender User
  # @param form SendLetterToPatientForm
  def call(patient_letter, sender, form)
    @patient_letter = patient_letter
    patient = patient_letter.patient
    business = patient.business

    case form.send_format
    when 'email'
      com = business.communications.create!(
        message_type: Communication::TYPE_EMAIL,
        recipient: patient,
        linked_patient_id: patient.id,
        category: 'letter_send',
        message: @patient_letter.content,
        source: @patient_letter
      )

      com_delivery = CommunicationDelivery.create!(
        communication_id: com.id,
        recipient: patient.email,
        tracking_id: SecureRandom.base58(32),
        last_tried_at: Time.current,
        status: CommunicationDelivery::STATUS_SCHEDULED,
        provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
      )

      PatientLetterMailer.email_letter(
        patient_letter,
        sender,
        form.email_subject,
        sendgrid_delivery_tracking_id: com_delivery.tracking_id
      ).deliver_later

    when 'attachment'
      com = business.communications.create!(
        message_type: Communication::TYPE_EMAIL,
        recipient: patient,
        linked_patient_id: patient.id,
        category: 'letter_send',
        message: form.email_content,
        source: @patient_letter
      )

      com_delivery = CommunicationDelivery.create!(
        communication_id: com.id,
        recipient: patient.email,
        tracking_id: SecureRandom.base58(32),
        last_tried_at: Time.current,
        status: CommunicationDelivery::STATUS_SCHEDULED,
        provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
      )

      PatientLetterMailer.attachment_letter(
        patient_letter,
        sender,
        form.email_subject,
        form.email_content,
        sendgrid_delivery_tracking_id: com_delivery.tracking_id
      ).deliver_later

    else
      raise Exception, "Unknown send format: '#{form.send_format}'"
    end
  end
end
