class ReviewMailer < ApplicationMailer
  def review_request_mail(appointment)
    @appointment = appointment
    @practitioner = appointment.practitioner
    @patient  = appointment.patient
    @business = @practitioner.business
    @template = @business.get_communication_template('satisfaction_review_request')
    @content  = Letter::Renderer.new(@patient, @template).render([
                @patient,
                @practitioner,
                @business,
                @appointment
              ])

    @template.attachments.each do |template_atm|
      attachments[template_atm.attachment_file_name] =
        Paperclip.io_adapters.for(template_atm.attachment).read
    end

    com = @business.communications.create!(
      message_type: Communication::TYPE_EMAIL,
      category: 'satisfaction_review_request',
      linked_patient_id: @patient.id,
      recipient: @patient,
      message: @content.content,
      source: @appointment
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
      subject: @template.email_subject.presence || "Request for review for #{@practitioner.full_name}"
    ))
  end

  def review_submitted_email(review)
    @review = review
    @practitioner = @review.practitioner
    @patient = @review.patient

    mail to: @practitioner.email,
         cc: @practitioner.business.email,
         subject: "Review submitted for #{@practitioner.full_name}"
  end
end
