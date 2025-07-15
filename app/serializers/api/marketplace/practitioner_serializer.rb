module Api
  module Marketplace
    class PractitionerSerializer
      attr_reader :practitioner

      def initialize(practitioner)
        @practitioner = practitioner
      end

      def as_json(_options = {})
        data = practitioner.attributes.symbolize_keys.slice(
          :id, :first_name, :last_name, :email, :profession, :medicare,
          :phone, :mobile, :address1, :address2, :city, :state, :postcode, :country,
          :summary, :education, :updated_at, :created_at
        )

        data[:avatar] =
          if practitioner.user.avatar.exists?
            practitioner.user.avatar.url
          else
            nil
          end

        data[:business] = Api::Marketplace::BusinessSerializer.new(practitioner.business)

        data
      end
    end
  end
end
