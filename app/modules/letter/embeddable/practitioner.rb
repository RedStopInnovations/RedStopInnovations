module Letter
  module Embeddable
    class Practitioner < Base
      VARIABLES = [
        'Practitioner.FullName',
        'Practitioner.FirstName',
        'Practitioner.LastName',
        'Practitioner.Profession',
        'Practitioner.Medicare',
        'Practitioner.Email',
        'Practitioner.Mobile',
        'Practitioner.Phone',
        'Practitioner.FullAddress',
        'Practitioner.Address1',
        'Practitioner.Address2',
        'Practitioner.City',
        'Practitioner.State',
        'Practitioner.PostCode',
        'Practitioner.Country',
        'Practitioner.Signature',
      ]

      # @param practitioner ::Practitioner
      def initialize(practitioner)
        @practitioner = practitioner
        @attributes = map_attributes
      end

      private

      def map_attributes
        map = {}

        map['Practitioner.FullName'] = @practitioner.full_name
        map['Practitioner.FirstName'] = @practitioner.first_name
        map['Practitioner.LastName'] = @practitioner.last_name
        map['Practitioner.Profession'] = @practitioner.profession
        map['Practitioner.Medicare'] = @practitioner.medicare
        map['Practitioner.Email'] = @practitioner.user_email
        map['Practitioner.Mobile'] = @practitioner.mobile
        map['Practitioner.Phone'] = @practitioner.phone
        map['Practitioner.FullAddress'] = @practitioner.full_address
        map['Practitioner.Address1'] = @practitioner.address1
        map['Practitioner.Address2'] = @practitioner.address2
        map['Practitioner.City'] = @practitioner.city
        map['Practitioner.State'] = @practitioner.state
        map['Practitioner.PostCode'] = @practitioner.postcode
        map['Practitioner.Country'] = @practitioner.country

        signature_tag = "<img src='#{@practitioner.signature.url(:medium)}'/>"
        map['Practitioner.Signature'] = @practitioner.signature.exists? ? signature_tag : ""

        map
      end
    end
  end
end
