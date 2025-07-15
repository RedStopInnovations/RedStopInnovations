module NotificationTemplate
  module Embeddable
    class Business < Base
      VARIABLES = [
        'Business.Name',
        'Business.Email',
        'Business.Mobile',
        'Business.Phone',
        'Business.FullAddress',
        'Business.Address1',
        'Business.Address2',
        'Business.City',
        'Business.State',
        'Business.PostCode',
        'Business.Country'
      ]

      # @param business ::Business
      def initialize(business)
        @business = business
        super map_attributes
      end

      private

      def map_attributes
        map = {}
        map['Business.Name'] = @business.name
        map['Business.Email'] = @business.email
        map['Business.Mobile'] = @business.mobile
        map['Business.Phone'] = @business.phone
        map['Business.FullAddress'] = @business.full_address
        map['Business.Address1'] = @business.address1
        map['Business.Address2'] = @business.address2
        map['Business.City'] = @business.city
        map['Business.State'] = @business.state
        map['Business.PostCode'] = @business.postcode
        map['Business.Country'] = @business.country

        map
      end
    end
  end
end
