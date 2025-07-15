module ClinikoApi
  module Resource
    class Contact < Base
      class PhoneNumber
        include Virtus.model
        attribute :number, String
        attribute :phone_type, String
        attribute :normalized_number, String
      end

      attribute :id, String
      attribute :title, String
      attribute :first_name, String
      attribute :last_name, String
      attribute :email, String
      attribute :company_name, String
      attribute :doctor_type, String
      attribute :occupation, String
      attribute :preferred_name, String
      attribute :provider_number, String

      attribute :notes, String

      attribute :address_1, String
      attribute :address_2, String
      attribute :address_3, String
      attribute :city, String
      attribute :post_code, String
      attribute :state, String
      attribute :country, String
      attribute :country_code, String
      attribute :type, String
      attribute :type_code, String

      attribute :created_at, DateTime
      attribute :updated_at, DateTime
      attribute :archived_at, DateTime
      attribute :deleted_at, DateTime

      attribute :phone_numbers, Array[PhoneNumber]
    end
  end
end
