module Letter
  module Embeddable
    class DoctorContact < Base
      VARIABLES = [
        'Doctor.ContactName',
        'Doctor.Title',
        'Doctor.FirstName',
        'Doctor.LastName',
        'Doctor.FullName',
        'Doctor.Email',
        'Doctor.Phone',
        'Doctor.Mobile',
        'Doctor.Fax',
        'Doctor.FullAddress',
        'Doctor.Address1',
        'Doctor.Address2',
        'Doctor.City',
        'Doctor.State',
        'Doctor.PostCode',
        'Doctor.Country'
      ]

      # @param patient ::Contact
      def initialize(contact)
        @contact = contact
        super map_attributes
      end

      private

      def map_attributes
        map = {
          'Doctor.ContactName' => @contact.business_name,
          'Doctor.Title' => @contact.title,
          'Doctor.FirstName' => @contact.first_name,
          'Doctor.LastName' => @contact.last_name,
          'Doctor.FullName' => @contact.full_name,
          'Doctor.Email' => @contact.email,
          'Doctor.Phone' => @contact.phone,
          'Doctor.Mobile' => @contact.mobile,
          'Doctor.Fax' => @contact.fax,
          'Doctor.FullAddress' => @contact.full_address,
          'Doctor.Address1' => @contact.address1,
          'Doctor.Address2' => @contact.address2,
          'Doctor.City' => @contact.city,
          'Doctor.State' => @contact.state,
          'Doctor.PostCode' => @contact.postcode,
          'Doctor.Country' => @contact.country
        }
        map
      end

    end
  end
end
