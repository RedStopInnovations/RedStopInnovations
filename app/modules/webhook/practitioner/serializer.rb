module Webhook
  module Practitioner
    class Serializer

      attr_reader :practitioner

      def initialize(practitioner)
        @practitioner = practitioner
      end

      def as_json(options = {})
        attrs = practitioner.attributes.symbolize_keys.slice(
          :id,
          :first_name,
          :last_name,
          :active,
          :education,
          :profession,
          :ahpra,
          :medicare,
          :phone,
          :mobile,
          :address1,
          :address2,
          :city,
          :state,
          :postcode,
          :country,
          :summary,
          :updated_at,
          :created_at,
          :metadata
        )
        attrs
      end
    end
  end
end
