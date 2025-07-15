module Webhook
  module Payment
    class CreatedEventHandler

      attr_reader :payment

      def initialize(payment)
        @payment = payment
      end

      def call
        subs = WebhookSubscription.where(
          event: WebhookSubscription::PAYMENT_CREATED,
          active: true,
          business_id: payment.business&.id
        )

        subs.each do |sub|
            uri = URI.parse(sub.target_url)
            begin
              http = Net::HTTP.new(uri.host, uri.port)
              request = Net::HTTP::Post.new(
                uri.request_uri,
                'Content-Type' => 'application/json'
              )
              http.use_ssl = (uri.scheme == 'https')
              request.body = build_payload
              res = http.request(request)
              # If Zapier responds with a 410, we will remove the subscription
            rescue => e
              Sentry.capture_exception(e)
            end
        end
      end

      def build_payload
        Serializer.new(payment).as_json.to_json
      end
    end
  end
end