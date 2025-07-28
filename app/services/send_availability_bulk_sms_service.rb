class SendAvailabilityBulkSmsService
  attr_reader :business, :availability, :form_request

  def call(business, availability, form_request)
    @business = business
    @availability = availability
    @form_request = form_request
    send_time = Time.current

    result = OpenStruct.new(success: true)
    failures_count = 0

    availability.appointments.each do |appointment|
      patient = appointment.patient

      if patient.mobile_formated.present?
        perform_send =
          if form_request.send_option == 'FORCE_ALL'
            true
          elsif form_request.send_option == 'SKIP_REMINDER_DISABLED'
            patient.reminder_enable?
          end

        if perform_send
          sms_content = build_sms_content(appointment)

          com = business.communications.create!(
            message_type: Communication::TYPE_SMS,
            category: form_request.communication_category,
            recipient: patient,
            linked_patient_id: patient.id,
            message: sms_content,
            source: appointment,
            direction: Communication::DIRECTION_OUTBOUND
          )

          begin
            com_delivery = CommunicationDelivery.new(
              communication_id: com.id,
              recipient: patient.mobile_formated,
              tracking_id: SecureRandom.base58(32),
              last_tried_at: send_time,
              provider_id: CommunicationDelivery::PROVIDER_ID_TWILIO,
              status: CommunicationDelivery::STATUS_SCHEDULED
            )
            com_delivery.save

            status_callback_url =
              if Rails.env.production?
                Rails.application.routes.url_helpers.twilio_sms_delivery_hook_url(tracking_id: com_delivery.tracking_id)
              end

            twilio_message_from = business.sms_settings.enabled_two_way? ? business.sms_settings.twilio_number : ENV['TWILIO_MESSAGE_DEFAULT_FROM']

            twilio_message = Twilio::REST::Client.new.messages.create(
              from: twilio_message_from,
              body: sms_content,
              to: patient.mobile_formated,
              status_callback: status_callback_url
            )

            com_delivery.provider_resource_id = twilio_message.sid
            com_delivery.provider_delivery_status = twilio_message.status
            com_delivery.status = CommunicationDelivery::STATUS_PROCESSED

            billing_item = SubscriptionBillingService.new.create_sms_billing_item(
              business, "Send message to client", appointment
            )

            UpdateSmsBillingItemQuantityWorker.perform_at(3.minutes.from_now, billing_item.id, twilio_message.sid)
          rescue => e
            failures_count += 1
            com_delivery.status = CommunicationDelivery::STATUS_ERROR
            com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INTERNAL_ERROR
            com_delivery.provider_metadata = {
              error_code: e.code,
              error_message: e.message
            }

            unless com_delivery.error_type == CommunicationDelivery::DELIVERY_ERROR_TYPE_INVALID_RECIPIENT
              Sentry.capture_exception(e)
            end
          ensure
            com_delivery.save if com_delivery
          end

        end
      end

    end

    if failures_count > 0
      result.success = false
    end

    result
  end

  private

  def build_sms_content(appointment)
    patient = appointment.patient
    practitioner = appointment.practitioner
    business = practitioner.business

    template = CommunicationTemplate.new(
      content: form_request.content
    )

    result = Letter::Renderer.new(patient, template).render([
      business,
      practitioner,
      appointment
    ])

    result.content
  end

end