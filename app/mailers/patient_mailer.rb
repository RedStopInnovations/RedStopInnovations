class PatientMailer < ApplicationMailer
  helper :application

  def new_patient_confirmation(patient)
    @patient = patient
    business = patient.business

    com_template = business.get_communication_template(CommunicationTemplate::TEMPLATE_ID_NEW_PATIENT_CONFIRMATION)

    com_template_renderred = Letter::Renderer.new(patient, com_template).
      render([
        patient,
        business
      ])

    com_template.attachments.each do |template_atm|
      attachments[template_atm.attachment_file_name] =
        Paperclip.io_adapters.for(template_atm.attachment).read
    end

    # Create communication
    com = business.communications.create!(
      message_type: Communication::TYPE_EMAIL,
      category: 'new_patient_confirmation',
      linked_patient_id: patient.id,
      recipient: patient,
      message: com_template_renderred.content,
      direction: Communication::DIRECTION_OUTBOUND
    )

    CommunicationDelivery.create!(
      communication_id: com.id,
      recipient: patient.email,
      tracking_id: SecureRandom.base58(32),
      last_tried_at: Time.current,
      status: CommunicationDelivery::STATUS_SCHEDULED,
      provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
    )

    @email_body = com_template_renderred.content

    mail(business_email_options(business).merge(
      to: patient.email,
      subject: com_template.email_subject
    ))
  end
end
