class SendGridEmailDeliveryHookHandleService
  attr_reader :hook_data

  DELIVERY_STATUSES = ['processed', 'bounce', 'dropped', 'deferred', 'delivered']
  DELIVERY_ERROR_STATUSES = ['bounce', 'dropped', 'deferred']

  # @see: https://docs.sendgrid.com/for-developers/tracking-events/event
  def call(hook_data)
    @hook_data = hook_data

    hook_data['_json'].each do |event|
      email_status = event['event']
      if DELIVERY_STATUSES.include? email_status
        provided_message_id = event['sg_message_id']
        next if provided_message_id.nil?

        message_id = provided_message_id.split('.')[0]
        delivery_tracking_id = event[App::EMAIL_DELIVERY_TRACKING_FIELD_NAME]

        if delivery_tracking_id.present?
          com_delivery = CommunicationDelivery.find_by(
            provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID,
            tracking_id: delivery_tracking_id
          )

          # @TODO: ignore if the current status is final?
          if com_delivery && com_delivery.created_at >= 3.days.ago

            provider_metadata = com_delivery.provider_metadata || {}
            unless provider_metadata['events'].present?
              provider_metadata['events'] = []
            end

            provider_metadata['events'] << event

            if !com_delivery.provider_resource_id.present?
              com_delivery.provider_resource_id = message_id
            end

            com_delivery.provider_delivery_status = email_status
            com_delivery.provider_metadata = provider_metadata
            com_delivery.status = parse_delivery_status(event)

            if DELIVERY_ERROR_STATUSES.include?(email_status)
              com_delivery.error_type = parse_delivery_error_type(event)
              com_delivery.error_message = parse_delivery_error_message(event)
            end

            com_delivery.save!
          end
        end

      end
    end
  end

  private

  def parse_delivery_status(event)
    {
      'processed' => CommunicationDelivery::STATUS_PROCESSED,
      'bounce'    => CommunicationDelivery::STATUS_ERROR,
      'dropped'   => CommunicationDelivery::STATUS_ERROR,
      'deferred'  => CommunicationDelivery::STATUS_ERROR,
      'delivered' => CommunicationDelivery::STATUS_DELIVERED
    }[event['event']]
  end

  def parse_delivery_error_type(event)
    if ['bounce', 'dropped', 'deferred'].include? event['event']
      CommunicationDelivery::DELIVERY_ERROR_TYPE_UNREACHABLE
    else
      CommunicationDelivery::DELIVERY_ERROR_TYPE_UNKNOWN
    end
  end

  def parse_delivery_error_message(event)
    if event['reason'].present?
      event['reason']
    else
      event['bounce_classification'] # Invalid Address, Technical, Content, Reputation, Frequency/Volume, Mailbox Unavailable, or Unclassified.
    end
  end
end
