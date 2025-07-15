class SendPatientMessageService
  class FeatureNotAvailable < StandardError; end
  class DeliveryFailed < StandardError; end

  # @param business Business
  # @param form SendPatientSmsForm
  # @param sender User
  def call(business, form, sender)
    # Only send if the business subscription has payment method added
    if business.in_trial_period? || !business.subscription.credit_card_added?
      raise FeatureNotAvailable, 'The feature is not available for this account.'
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

        com_delivery.status = CommunicationDelivery::STATUS_PROCESSED
        com_delivery.save

        twilio_message = Twilio::REST::Client.new.messages.create(
          messaging_service_sid: ENV['TWILIO_SMS_SERVICE_ID'],
          body: sms_content,
          to: patient.mobile_formated,
          status_callback: Rails.application.routes.url_helpers.twilio_sms_delivery_hook_url(tracking_id: com_delivery.tracking_id)
        )

        com_delivery.provider_resource_id = twilio_message.sid
        com_delivery.provider_delivery_status = twilio_message.status

        billing_item = SubscriptionBillingService.new.create_sms_billing_item(business, 'Send message to client')

        UpdateSmsBillingItemQuantityWorker.perform_at(3.minutes.from_now, billing_item.id, twilio_message.sid)
      rescue => e
        provider_metadata = {}
        com_delivery.status = CommunicationDelivery::STATUS_ERROR
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
            com_delivery.error_type = CommunicationDelivery::DELIVERY_ERROR_TYPE_UNKNOWN
          end
        end

        com_delivery.provider_metadata = provider_metadata

        unless com_delivery.error_type == CommunicationDelivery::DELIVERY_ERROR_TYPE_INVALID_RECIPIENT
          Sentry.capture_exception(e)
        end

        com_delivery.save

        raise DeliveryFailed, e.message
      end
  end
end