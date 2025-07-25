class AppointmentNotificationService
  attr_reader :appointment, :notification_type_id

  def call(appointment, notification_type_id)
    @appointment = appointment
    patient = appointment.patient
    practitioner = appointment.practitioner
    business = practitioner.business

    @notification_type_id = notification_type_id

    notify_setting = NotificationTypeSetting.find_by(
      business_id: business.id,
      notification_type_id: notification_type_id,
    )

    if notify_setting && notify_setting.enabled?

      if notify_setting.enabled_email_delivery?
        case notify_setting.notification_type_id
        when NotificationType::APPOINTMENT__CREATED
          AppointmentMailer.created_notification_to_practitioner(appointment.id).deliver_later
        when NotificationType::APPOINTMENT__BOOKED_ONLINE
          AppointmentMailer.booked_online_notification_to_practitioner(appointment.id).deliver_later
        when NotificationType::APPOINTMENT__UPDATED
          AppointmentMailer.updated_notification_to_practitioner(appointment.id).deliver_later
        when NotificationType::APPOINTMENT__CANCELLED
          AppointmentMailer.cancelled_notification_to_practitioner(appointment.id).deliver_later
        else
        end
      end

      if notify_setting.enabled_sms_delivery? && practitioner.mobile.present? && !business.in_trial_period?
        # && business.subscription.credit_card_added?
        sms_content = NotificationTemplate::Sms::Renderer.new(
          NotificationTemplate::Sms::Template.new(
            notify_setting.template['sms_content']),
            [
              appointment,
              patient,
              practitioner,
              business
            ]
          ).render.content

        twilio_message = Twilio::REST::Client.new.messages.create(
          messaging_service_sid: ENV['TWILIO_SMS_SERVICE_ID'],
          body: sms_content,
          to: standardize_practitioner_mobile(practitioner),
        )

        billing_item = SubscriptionBillingService.new.create_sms_billing_item(
          business, 'Send appointment notification to practitioner', appointment
        )

        UpdateSmsBillingItemQuantityWorker.perform_at(3.minutes.from_now, billing_item.id, twilio_message.sid)
      end
    end
  end

  private

  def standardize_practitioner_mobile(practitioner)
    country = practitioner.country.presence || practitioner.business.country
    TelephoneNumber.parse(practitioner.mobile, country).e164_number
  end
end