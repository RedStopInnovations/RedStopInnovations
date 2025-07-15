module Webhook
  module Appointment
    class CreatedEventHandler

      attr_reader :appointment

      def initialize(appointment)
        @appointment = appointment
      end

      def call
        subs = WebhookSubscription.where(
          event: 'appointment_created',
          active: true,
          business_id: appointment.practitioner.business_id
        )

        threads = []
        # Thread.abort_on_exception = false
        subs.each do |sub|
          # Thread.new do
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
          # end
        end

        # threads.each(&:join)
      end

      def build_payload
        Serializer.new(appointment).as_json.to_json
      end
    end
  end
end
