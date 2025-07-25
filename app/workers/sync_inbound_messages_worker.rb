class SyncInboundMessagesWorker
  include Sidekiq::Worker

  def perform
    begin
      sync_inbound_messages
    rescue => e
      Rails.logger.error "SyncInboundMessages failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def sync_inbound_messages
    twilio_api_client = Twilio::REST::Client.new
    processed_count = 0
    error_count = 0

    # Get all businesses with SMS settings and their Twilio numbers
    # Map from business_id to twilio_number
    business_numbers = SmsSettings.joins(:business)
                                 .where(enabled_two_way: true)
                                 .where.not(twilio_number: nil)
                                 .pluck(:business_id, :twilio_number)
                                 .to_h

    if business_numbers.empty?
      Rails.logger.info "No businesses with two-way SMS enabled found"
      return
    end

    Rails.logger.info "Syncing inbound messages for #{business_numbers.size} businesses"

    # Fetch all messages with pagination
    messages = []
    # TODO: remember the last fetch timestamp instead of hardcoding 3 minutes
    # @see: https://www.twilio.com/docs/messaging/api/message-resource#read-multiple-message-resources
    twilio_api_client.messages.list(date_sent_after: 3.minutes.ago, page_size: 100).each do |message|
      messages << message
    end

    # Filter for inbound SMS messages to our business numbers
    inbound_messages = messages.select do |message|
      message.direction == 'inbound' && business_numbers.values.include?(message.to)
    end

    Rails.logger.info "Found #{inbound_messages.size} inbound messages to process"

    inbound_messages.each do |twilio_message|
      begin
        # Find the business by matching the 'to' number
        business_id = business_numbers.key(twilio_message.to)
        next unless business_id

        process_inbound_message(twilio_message, business_id)
        processed_count += 1
      rescue => e
        error_count += 1
        Rails.logger.error "Failed to process message #{twilio_message.sid}: #{e.message}"
        next
      end
    end

    Rails.logger.info "Processed #{processed_count} messages successfully, #{error_count} errors"
  end

  def process_inbound_message(twilio_message, business_id)
    business = Business.find(business_id)

    # Check if message already exists to avoid duplicates
    existing_delivery = CommunicationDelivery.find_by(
      provider_id: CommunicationDelivery::PROVIDER_ID_TWILIO,
      provider_resource_id: twilio_message.sid
    )
    return if existing_delivery

    # Find linked patient by matching from number with mobile_formated
    linked_patient = business.patients.find_by(mobile_formated: twilio_message.from)
    message_sent_at = twilio_message.date_sent

    # Create Communication record
    communication = Communication.create!(
      business_id: business.id,
      message_type: Communication::TYPE_SMS,
      direction: Communication::DIRECTION_INBOUND,
      from: twilio_message.from,
      message: twilio_message.body,
      linked_patient_id: linked_patient&.id,
      recipient_type: 'Business',
      recipient_id: business.id,
      category: 'general',
      created_at: message_sent_at,
    )

    # Create CommunicationDelivery record
    CommunicationDelivery.create!(
      communication_id: communication.id,
      recipient: twilio_message.to,
      status: CommunicationDelivery::STATUS_DELIVERED,
      provider_id: CommunicationDelivery::PROVIDER_ID_TWILIO,
      provider_resource_id: twilio_message.sid,
      provider_delivery_status: twilio_message.status,
      tracking_id: SecureRandom.base58(32),
      last_tried_at: message_sent_at,
      provider_metadata: {
        'sid' => twilio_message.sid,
        'from' => twilio_message.from,
        'to' => twilio_message.to,
        'status' => twilio_message.status,
        'account_sid' => twilio_message.account_sid,
        'messaging_service_sid' => twilio_message.messaging_service_sid,
        'date_sent' => twilio_message.date_sent,
        'date_created' => twilio_message.date_created,
        'direction' => twilio_message.direction,
        'num_segments' => twilio_message.num_segments,
        'error_code' => twilio_message.error_code,
        'error_message' => twilio_message.error_message,
        'num_segments' => twilio_message.num_segments,
      }
    )

    Rails.logger.debug "Created inbound SMS communication #{communication.id} for business #{business.id}"
  end
end