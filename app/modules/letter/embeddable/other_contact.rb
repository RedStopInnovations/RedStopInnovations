module Letter
  module Embeddable
    class OtherContact < Base
      VARIABLES = [
        'OtherContact.ContactName',
        'OtherContact.Title',
        'OtherContact.FirstName',
        'OtherContact.LastName',
        'OtherContact.FullName',
        'OtherContact.Email',
        'OtherContact.Phone',
        'OtherContact.Mobile',
        'OtherContact.Fax',
        'OtherContact.FullAddress',
        'OtherContact.Address1',
        'OtherContact.Address2',
        'OtherContact.City',
        'OtherContact.State',
        'OtherContact.PostCode',
        'OtherContact.Country'
      ]

      # @param patient ::Contact
      def initialize(contact)
        @contact = contact
        super map_attributes
      end

      private

      def map_attributes
        map = {
          'OtherContact.ContactName' => @contact.business_name,
          'OtherContact.Title' => @contact.title,
          'OtherContact.FirstName' => @contact.first_name,
          'OtherContact.LastName' => @contact.last_name,
          'OtherContact.FullName' => @contact.full_name,
          'OtherContact.Email' => @contact.email,
          'OtherContact.Phone' => @contact.phone,
          'OtherContact.Mobile' => @contact.mobile,
          'OtherContact.Fax' => @contact.fax,
          'OtherContact.FullAddress' => @contact.full_address,
          'OtherContact.Address1' => @contact.address1,
          'OtherContact.Address2' => @contact.address2,
          'OtherContact.City' => @contact.city,
          'OtherContact.State' => @contact.state,
          'OtherContact.PostCode' => @contact.postcode,
          'OtherContact.Country' => @contact.country
        }
        map
      end

    end
  end
end
