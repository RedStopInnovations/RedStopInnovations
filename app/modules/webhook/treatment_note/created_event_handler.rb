module Webhook
  module TreatmentNote
    class CreatedEventHandler

      attr_reader :treatment_note

      def initialize(treatment_note)
        @treatment_note = treatment_note
      end

      def call
        subs = WebhookSubscription.where(
          event: WebhookSubscription::TREATMENT_NOTE_CREATED,
          active: true,
          business_id: treatment_note.author.business_id
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
        Serializer.new(treatment_note).as_json.to_json
      end
    end
  end
end