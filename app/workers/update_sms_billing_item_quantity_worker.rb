# After request to Twilio to send an SMS, there is a delay to get number of message segments.
# This will fetch message to get the segments, then update "quantity" of the given billing item(SubscriptionBilling object)
class UpdateSmsBillingItemQuantityWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3

  def perform(billing_item_id, twilio_message_sid)
    billing_item = SubscriptionBilling.find_by(id: billing_item_id)

    if billing_item
      twilio_message = Twilio::REST::Client.new.messages.find(twilio_message_sid)
      num_segments = twilio_message.num_segments.to_i
      if num_segments > 0
        billing_item.update_column :quantity, num_segments
      end

      if num_segments >= 5
        # Just a warning to be noticed
        Sentry.capture_message("There is an SMS have too many segments(#{num_segments})! Message sid: #{twilio_message_sid}")
      end
    end
  end
end
