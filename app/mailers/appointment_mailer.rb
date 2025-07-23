class AppointmentMailer < ApplicationMailer
  # Send details to patient after booking an appointment
  def booking_confirmation(appointment_id)
    @appointment  = Appointment.find appointment_id
    @practitioner = @appointment.practitioner
    @patient      = @appointment.patient
    @business     = @practitioner.business
    @template     = @business.get_communication_template('appointment_confirmation')
    @content = Letter::Renderer.new(@patient, @template).
      render([
        @appointment,
        @patient,
        @practitioner,
        @business
      ])

    @template.attachments.each do |template_atm|
      attachments[template_atm.attachment_file_name] =
        Paperclip.io_adapters.for(template_atm.attachment).read
    end

    # Create communication
    com = @business.communications.create!(
      message_type: Communication::TYPE_EMAIL,
      category: 'appointment_confirmation',
      linked_patient_id: @patient.id,
      recipient: @patient,
      message: @content.content,
      source: @appointment,
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

    mail(business_email_options(@practitioner.business).merge(
      to: @patient.email,
      subject: @template.email_subject.presence || "Appointment booking confirmation"
    ))
  end

  # Notification type: appointment.created
  def created_notification_to_practitioner(appointment_id)
    @appointment  = Appointment.unscoped.find(appointment_id)
    @patient      = @appointment.patient
    @practitioner = @appointment.practitioner
    @practitioner_user = @practitioner.user
    @business = @practitioner_user.business

    notif_setting = NotificationTypeSetting.find_by(
      business_id: @business.id,
      notification_type_id: NotificationType::APPOINTMENT__CREATED
    )

    if notif_setting
      render_result = NotificationTemplate::Email::Renderer.new(
        NotificationTemplate::Email::Template.new(
          notif_setting.template['email_subject'],
          notif_setting.template['email_body']
        ),
        [
          @appointment,
          @patient,
          @practitioner,
          @business
        ]
      ).render

      mail(business_email_options(@practitioner_user.business).merge(
        to: @practitioner_user.email,
        subject: render_result.subject,
        content_type: "text/html",
        body: render_result.body
      ))
    else
      mail(business_email_options(@practitioner_user.business).merge(
        to: @practitioner_user.email,
        subject: 'Appointment created confirmation'
      ))
    end
  end

  # Notification: appointment.booked_online
  def booked_online_notification_to_practitioner(appointment_id)
    @appointment  = Appointment.unscoped.find(appointment_id)
    @patient      = @appointment.patient
    @practitioner = @appointment.practitioner
    @practitioner_user = @practitioner.user
    @business = @practitioner_user.business

    notif_setting = NotificationTypeSetting.find_by(
      business_id: @business.id,
      notification_type_id: NotificationType::APPOINTMENT__BOOKED_ONLINE
    )

    if notif_setting
      render_result = NotificationTemplate::Email::Renderer.new(
        NotificationTemplate::Email::Template.new(
          notif_setting.template['email_subject'],
          notif_setting.template['email_body']
        ),
        [
          @appointment,
          @patient,
          @practitioner,
          @business
        ]
      ).render

      mail(business_email_options(@practitioner_user.business).merge(
        to: @practitioner_user.email,
        subject: render_result.subject,
        content_type: "text/html",
        body: render_result.body
      ))
    else
      mail(business_email_options(@practitioner_user.business).merge(
        to: @practitioner_user.email,
        subject: 'Appointment booked online confirmation'
      ))
    end
  end

  # Notification: appointment.updated
  def updated_notification_to_practitioner(appointment_id)
    @appointment  = Appointment.unscoped.find(appointment_id)
    @patient      = @appointment.patient
    @practitioner = @appointment.practitioner
    @practitioner_user = @practitioner.user
    @business = @practitioner_user.business

    notif_setting = NotificationTypeSetting.find_by(
      business_id: @business.id,
      notification_type_id: NotificationType::APPOINTMENT__UPDATED
    )

    if notif_setting
      render_result = NotificationTemplate::Email::Renderer.new(
        NotificationTemplate::Email::Template.new(
          notif_setting.template['email_subject'],
          notif_setting.template['email_body']
        ),
        [
          @appointment,
          @patient,
          @practitioner,
          @business
        ]
      ).render

      mail(business_email_options(@practitioner_user.business).merge(
        to: @practitioner_user.email,
        subject: render_result.subject,
        content_type: "text/html",
        body: render_result.body
      ))
    else
      mail(business_email_options(@practitioner_user.business).merge(
        to: @practitioner_user.email,
        subject: 'Appointment updated confirmation'
      ))
    end
  end

  # Notification: appointment.cancelled
  def cancelled_notification_to_practitioner(appointment_id)
    @appointment  = Appointment.unscoped.find(appointment_id)
    @patient      = @appointment.patient
    @practitioner = @appointment.practitioner
    @practitioner_user = @practitioner.user
    @business = @practitioner_user.business

    notif_setting = NotificationTypeSetting.find_by(
      business_id: @business.id,
      notification_type_id: NotificationType::APPOINTMENT__CANCELLED
    )

    if notif_setting
      render_result = NotificationTemplate::Email::Renderer.new(
        NotificationTemplate::Email::Template.new(
          notif_setting.template['email_subject'],
          notif_setting.template['email_body']
        ),
        [
          @appointment,
          @patient,
          @practitioner,
          @business
        ]
      ).render

      mail(business_email_options(@practitioner_user.business).merge(
        to: @practitioner_user.email,
        subject: render_result.subject,
        content_type: "text/html",
        body: render_result.body
      ))
    else
      mail(business_email_options(@practitioner_user.business).merge(
        to: @practitioner_user.email,
        subject: 'Appointment cancelled confirmation'
      ))
    end
  end
end
