module Letter
  module Embeddable
    class ReferrerContact < Base
      VARIABLES = [
        'Referrer.ContactName',
        'Referrer.Title',
        'Referrer.FirstName',
        'Referrer.LastName',
        'Referrer.FullName',
        'Referrer.Email',
        'Referrer.Phone',
        'Referrer.Mobile',
        'Referrer.Fax',
        'Referrer.FullAddress',
        'Referrer.Address1',
        'Referrer.Address2',
        'Referrer.City',
        'Referrer.State',
        'Referrer.PostCode',
        'Referrer.Country'
      ]

      # @param patient ::Contact
      def initialize(contact)
        @contact = contact
        super map_attributes
      end

      private

      def map_attributes
        map = {
          'Referrer.ContactName' => @contact.business_name,
          'Referrer.Title' => @contact.title,
          'Referrer.FirstName' => @contact.first_name,
          'Referrer.LastName' => @contact.last_name,
          'Referrer.FullName' => @contact.full_name,
          'Referrer.Email' => @contact.email,
          'Referrer.Phone' => @contact.phone,
          'Referrer.Mobile' => @contact.mobile,
          'Referrer.Fax' => @contact.fax,
          'Referrer.FullAddress' => @contact.full_address,
          'Referrer.Address1' => @contact.address1,
          'Referrer.Address2' => @contact.address2,
          'Referrer.City' => @contact.city,
          'Referrer.State' => @contact.state,
          'Referrer.PostCode' => @contact.postcode,
          'Referrer.Country' => @contact.country
        }
        map
      end

    end
  end
end
