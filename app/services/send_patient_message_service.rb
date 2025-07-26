class SendPatientMessageService
  class FeatureNotAvailable < StandardError; end
  class DeliveryFailed < StandardError; end

  # @param business Business
  # @param form SendPatientSmsForm
  # @param sender User
  def call(business, form, sender)
    # Only send if the business subscription has payment method added
    if !business.sms_settings&.enabled?
      raise FeatureNotAvailable, 'The feature is not available on your account.'
    end

    patient = business.patients.find(form.patient_id)
    sms_content = form.content

    comm_category =
      if form.communication_category.present?
        form.communication_category
      else
        'general'
      end

      com = Communication.new(
        business_id: business.id,
        message_type: Communication::TYPE_SMS,
        category: comm_category,
        recipient: patient,
        linked_patient_id: patient.id,
        message: sms_content
      )

      if form.source_id.present? && form.source_type.present?
        com.source_id = form.source_id
        com.source_type = form.source_type
      end

      com.save!(validate: false)

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

        status_callback_url =
          if Rails.env.production?
            twilio_sms_delivery_hook_url(tracking_id: com_delivery.tracking_id)
          end

        twilio_message_from = business.sms_settings.enabled_two_way? ? business.sms_settings.twilio_number : ENV['TWILIO_MESSAGE_SERVICE_SID']

        twilio_message = Twilio::REST::Client.new.messages.create(
          from: twilio_message_from,
          body: sms_content,
          to: patient.mobile_formated,
          status_callback: status_callback_url
        )

        com_delivery.provider_resource_id = twilio_message.sid
        com_delivery.provider_delivery_status = twilio_message.status

        billing_item = SubscriptionBillingService.new.create_sms_billing_item(business, 'Send message to client')

        UpdateSmsBillingItemQuantityWorker.perform_at(3.minutes.from_now, billing_item.id, twilio_message.sid)
      rescue => e
        com_delivery.status = CommunicationDelivery::STATUS_ERROR
        com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_INTERNAL_ERROR
        com_delivery.provider_metadata = {
          error_code: e.code,
          error_message: e.message
        }

        unless com_delivery.error_type == CommunicationDelivery::DELIVERY_ERROR_TYPE_INVALID_RECIPIENT
          Sentry.capture_exception(e)
        end

        com_delivery.save

        raise DeliveryFailed, e.message
      end
  end
end