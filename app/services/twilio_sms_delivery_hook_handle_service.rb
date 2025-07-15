class TwilioSmsDeliveryHookHandleService
  attr_reader :hook_data

  DELIVERY_STATUSES = ['queued', 'accepted', 'sending', 'sent', 'delivered', 'failed', 'undelivered']
  DELIVERY_ERROR_STATUSES = ['failed', 'undelivered']

  # @see: https://www.twilio.com/docs/sms/api/message-resource#statuscallback-request-parameters
  def call(hook_data, delivery_tracking_id)
    @hook_data = hook_data

    message_status = hook_data['MessageStatus']
    message_id = hook_data['MessageSid']

    if DELIVERY_STATUSES.include? message_status
      com_delivery = CommunicationDelivery.find_by(
        tracking_id: delivery_tracking_id
      )

      # @TODO: ignore if the current status is final?
      if com_delivery && com_delivery.created_at >= 3.days.ago
        provider_metadata = com_delivery.provider_metadata || {}
        unless provider_metadata['events'].present?
          provider_metadata['events'] = []
        end
        provider_metadata['events'] << hook_data

        com_delivery.provider_delivery_status = message_status
        com_delivery.provider_metadata = provider_metadata

        com_delivery.status = parse_delivery_status

        if DELIVERY_ERROR_STATUSES.include?(message_status)
          com_delivery.error_type = parse_delivery_error_type
          com_delivery.error_message = parse_delivery_error_message
        end

        com_delivery.save!
      end
    end
  end

  private

  def parse_delivery_status
    case hook_data['MessageStatus']
    when 'queued', 'accepted', 'sending', 'sent'
      CommunicationDelivery::STATUS_PROCESSED
    when 'failed', 'undelivered'
      CommunicationDelivery::STATUS_ERROR
    when 'delivered'
      CommunicationDelivery::STATUS_DELIVERED
    end
  end

  # @see: https://www.twilio.com/docs/sms/api/message-resource#delivery-related-errors
  def parse_delivery_error_type
    error_code = hook_data['ErrorCode'].to_s
    case error_code
    when '30003', '30004', '30005', '30006', '30007', '21612'
      CommunicationDelivery::DELIVERY_ERROR_TYPE_UNREACHABLE
    when '30001', '30002' # Queue overflow, Account suspended
      CommunicationDelivery::DELIVERY_ERROR_TYPE_SERVICE_ERROR
    else
      CommunicationDelivery::DELIVERY_ERROR_TYPE_UNKNOWN
    end
  end

  def parse_delivery_error_message
    if hook_data['ErrorMessage'].present?
      return hook_data['ErrorMessage']
    else
      error_code = hook_data['ErrorCode'].to_s
      case error_code
      when '21612'
        'The destination number is not currently reachable'
      when '30003'
        'The destination handset is switched off or otherwise unavailable.'
      when '30004'
        'The destination number is blocked from receiving the message.'
      when '30005'
        'The destination number is unknown and may no longer exist.'
      when '30006'
        'Landline or unreachable SMS carrier.'
      when '30007'
        'SMS carrier violation. The message was flagged as objectionable by the carrier.'
      when '30001', '30002' # Queue overflow, Account suspended
        'Technical error.'
      when '30008'
        'Unknown error'
      else
        'Unknown error'
      end
    end
  end
end
