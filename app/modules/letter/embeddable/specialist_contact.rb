module Letter
  module Embeddable
    class SpecialistContact < Base
      VARIABLES = [
        'Specialist.ContactName',
        'Specialist.Title',
        'Specialist.FirstName',
        'Specialist.LastName',
        'Specialist.FullName',
        'Specialist.Email',
        'Specialist.Phone',
        'Specialist.Mobile',
        'Specialist.Fax',
        'Specialist.FullAddress',
        'Specialist.Address1',
        'Specialist.Address2',
        'Specialist.City',
        'Specialist.State',
        'Specialist.PostCode',
        'Specialist.Country'
      ]

      # @param patient ::Contact
      def initialize(contact)
        @contact = contact
        super map_attributes
      end

      private

      def map_attributes
        map = {
          'Specialist.ContactName' => @contact.business_name,
          'Specialist.Title' => @contact.title,
          'Specialist.FirstName' => @contact.first_name,
          'Specialist.LastName' => @contact.last_name,
          'Specialist.FullName' => @contact.full_name,
          'Specialist.Email' => @contact.email,
          'Specialist.Phone' => @contact.phone,
          'Specialist.Mobile' => @contact.mobile,
          'Specialist.Fax' => @contact.fax,
          'Specialist.FullAddress' => @contact.full_address,
          'Specialist.Address1' => @contact.address1,
          'Specialist.Address2' => @contact.address2,
          'Specialist.City' => @contact.city,
          'Specialist.State' => @contact.state,
          'Specialist.PostCode' => @contact.postcode,
          'Specialist.Country' => @contact.country
        }
        map
      end

    end
  end
end
