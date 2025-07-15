class SendMultipleTreatmentNotesToOtherService

  # @param patient ::Patient
  # @param treatment_notes Array
  # @param form SendOthersForm
  def call(patient, treatment_notes, form)
    business = patient.business
    contacts = business.contacts.where(id: form.contact_ids)
    delegated_treatment_note = treatment_notes.first

    contacts.each do |contact|
      if contact.email.present?
        com = business.communications.create(
          message_type: Communication::TYPE_EMAIL,
          linked_patient_id: patient.id,
          recipient: contact,
          category: 'treatment_note_send',
          message: form.message,
          source: delegated_treatment_note
        )

        com_delivery = CommunicationDelivery.create!(
          communication_id: com.id,
          recipient: contact.email,
          tracking_id: SecureRandom.base58(32),
          last_tried_at: Time.current,
          status: CommunicationDelivery::STATUS_SCHEDULED,
          provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
        )

        PatientMailer.send_multiple_treatment_notes_to_contact(
          patient, treatment_notes, contact, form.message, sendgrid_delivery_tracking_id: com_delivery.tracking_id
        ).deliver_later
      end
    end

    form.emails.each do |email|
      PatientMailer.send_multiple_treatment_notes_to_email(
        patient, treatment_notes, email, form.message
      ).deliver_later
    end
  end
end
