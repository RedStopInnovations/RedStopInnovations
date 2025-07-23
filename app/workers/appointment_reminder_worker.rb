class AppointmentReminderWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3

  def perform(appointment_id)
    @appointment = Appointment.find_by(id: appointment_id)

    return if @appointment.nil?

    practitioner = @appointment.practitioner
    patient = @appointment.patient
    business = practitioner.business

    return if @appointment.start_time.past? || @appointment.cancelled_at? || @appointment.first_reminder_mail_sent

    # Check in case the appt is rescheduled
    days_diff_from_today = ((@appointment.start_time - Time.current) / 1.day).to_i.abs

    return unless days_diff_from_today <= 1

    return unless patient.reminder_enable?

    # Email reminder
    if patient.email? && business.communication_template_enabled?('appointment_reminder')
      com = Communication.new(
        message_type: Communication::TYPE_EMAIL,
        category: 'appointment_reminder',
        recipient: patient,
        linked_patient_id: patient.id,
        business_id: business.id,
        source: @appointment
      )
      reminder_email_content = build_reminder_mail_content
      com.message = reminder_email_content
      com.save!

      begin
        com_delivery = CommunicationDelivery.new(
          communication_id: com.id,
          recipient: patient.email,
          tracking_id: SecureRandom.base58(32),
          last_tried_at: Time.current,
          provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID,
          status: CommunicationDelivery::STATUS_SCHEDULED
        )

        com_delivery.save

        if patient.email.present?
          AppointmentReminderMailer.first_notification(
            appointment_id,
            sendgrid_delivery_tracking_id: com_delivery.tracking_id
          ).deliver_now!

          @appointment.update_column(:first_reminder_mail_sent, true)
        else
          com_delivery.status = CommunicationDelivery::STATUS_ERROR
          com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INVALID_RECIPIENT
          com_delivery.error_message = 'The email address is blank'
        end

      rescue => e
        com_delivery.status = CommunicationDelivery::STATUS_ERROR
        com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INTERNAL_ERROR
        Sentry.capture_exception(e)
      ensure
        if com_delivery
          com_delivery.save
        end
      end
    end

    # SMS reminder
    if patient.mobile? && business.communication_template_enabled?('appointment_reminder_sms')
      sms_content = build_reminder_sms_content

      com = business.communications.create!(
        message_type: 'SMS',
        category: 'appointment_reminder',
        recipient: patient,
        linked_patient_id: patient.id,
        message: sms_content,
        source: @appointment,
        direction: Communication::DIRECTION_OUTBOUND
      )

      begin
        com_delivery = CommunicationDelivery.new(
          communication_id: com.id,
          recipient: patient.mobile_formated,
          tracking_id: SecureRandom.base58(32),
          last_tried_at: Time.current,
          provider_id: CommunicationDelivery::PROVIDER_ID_TWILIO,
          status: CommunicationDelivery::STATUS_SCHEDULED
        )
        com_delivery.save

        if patient.mobile_formated.present?
          twilio_message = Twilio::REST::Client.new.messages.create(
            messaging_service_sid: ENV['TWILIO_SMS_SERVICE_ID'],
            body: sms_content,
            to: patient.mobile_formated,
            status_callback: Rails.application.routes.url_helpers.twilio_sms_delivery_hook_url(tracking_id: com_delivery.tracking_id)
          )
          com_delivery.provider_resource_id = twilio_message.sid
          com_delivery.provider_delivery_status = twilio_message.status
          com_delivery.status = CommunicationDelivery::STATUS_PROCESSED

          @appointment.update_column(:first_reminder_mail_sent, true)

          billing_item = SubscriptionBillingService.new.create_sms_billing_item(
            business,
            'Send appointment reminder to client',
            @appointment
          )

          UpdateSmsBillingItemQuantityWorker.perform_at(3.minutes.from_now, billing_item.id, twilio_message.sid)
        else
          com_delivery.status = CommunicationDelivery::STATUS_ERROR
          com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INVALID_RECIPIENT
          com_delivery.error_message = 'The mobile number is blank or not valid'
        end
      rescue => e
        provider_metadata = {}
        com_delivery.status = CommunicationDelivery::STATUS_ERROR

        # @see: https://www.twilio.com/docs/api/errors
        # @TODO: extract this to somewhere
        case e
        when Twilio::REST::ServerError
          com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_SERVICE_ERROR
          com_delivery.error_message = e.message
          provider_metadata['error_code'] = e.code
          provider_metadata['error_message'] = e.message
        when Twilio::REST::RequestError
          provider_metadata['error_code'] = e.code
          provider_metadata['error_message'] = e.message

          case e.code.to_s
          when '21211', '21214', '21612', '21614' # Invalid 'To' Phone Number, 'To' phone number cannot be reached
            com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INVALID_RECIPIENT
            com_delivery.error_message = e.message
          when '21212', '21408', '51001', '51002', '14107', '21603', '21606', '21611', '21618'
            com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INTERNAL_ERROR
          else
            com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INTERNAL_ERROR
          end
        end

        com_delivery.provider_metadata = provider_metadata

        Sentry.capture_exception(e) unless com_delivery.error_type == CommunicationDelivery::DELIVERY_ERROR_TYPE_INVALID_RECIPIENT
      ensure
        if com_delivery
          com_delivery.save
        end
      end
    end
  end

  private

  def build_reminder_sms_content
    patient = @appointment.patient
    practitioner = @appointment.practitioner
    business = practitioner.business
    template = business.get_communication_template('appointment_reminder_sms')
    result = Letter::Renderer.new(patient, template).render([
      business,
      practitioner,
      @appointment
    ])
    result.content
  end

  def build_reminder_mail_content
    practitioner = @appointment.practitioner
    patient = @appointment.patient
    business = practitioner.business
    template = business.get_communication_template('appointment_reminder')

    Letter::Renderer.new(patient, template).
      render([
        @appointment,
        patient,
        practitioner,
        business
      ]).content
  end
end
