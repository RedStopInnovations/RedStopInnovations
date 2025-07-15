module Api
  module Marketplace
    class BusinessSerializer
      attr_reader :business

      def initialize(business)
        @business = business
      end

      def as_json(_options = {})
        data = business.attributes.symbolize_keys.slice(
          :id, :name, :phone, :mobile, :fax, :email,
          :address1, :address2, :city, :state, :postcode, :country
        )

        data[:logo] =
          if business.avatar.exists?
            business.avatar.url
          else
            nil
          end
        data
      end
    end
  end
end
