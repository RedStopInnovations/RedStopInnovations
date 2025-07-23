class PatientAttachmentMailer < ApplicationMailer

  def send_to_contact(attachment, contact, message, options = {})
    @attachment = attachment
    @contact = contact
    @business = contact.business
    @message = message

    attachments[@attachment.attachment_file_name] =
      Paperclip.io_adapters.for(attachment.attachment).read

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_email_options(@business).merge(
      to: contact.email,
      subject: "Attachment #{@attachment.attachment_file_name} - #{@business.name}"
    ))
  end

  def send_to_patient(attachment)
    @attachment = attachment
    @patient = attachment.patient
    @business = @patient.business

    attachments[@attachment.attachment_file_name] =
      Paperclip.io_adapters.for(attachment.attachment).read

    com = @business.communications.create!(
      message_type: Communication::TYPE_EMAIL,
      linked_patient_id: @patient.id,
      recipient: @patient,
      category: 'patient_attachment_send',
      source: @attachment,
      direction: Communication::DIRECTION_OUTBOUND
    )

    com_delivery = CommunicationDelivery.create!(
      communication_id: com.id,
      recipient: @patient.email,
      tracking_id: SecureRandom.base58(32),
      last_tried_at: Time.current,
      status: CommunicationDelivery::STATUS_SCHEDULED,
      provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
    )

    add_sendgrid_delivery_tracking_header(com_delivery.tracking_id)

    mail(business_email_options(@business).merge(
      to: @patient.email,
      subject: "Attachment #{@attachment.attachment_file_name} - #{@business.name}"
    ))
  end

  def send_to_email(attachment, email, message)
    @attachment = attachment
    @patient = attachment.patient
    @business = @patient.business
    @message = message

    attachments[@attachment.attachment_file_name] =
      Paperclip.io_adapters.for(attachment.attachment).read

    mail(business_email_options(@business).merge(
      to: email,
      subject: "Attachment #{@attachment.attachment_file_name} - #{@business.name}"
    ))
  end
end
