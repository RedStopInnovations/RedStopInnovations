module ClinikoApi
  module Resource
    class Patient < Base
      class PhoneNumber
        include Virtus.model
        attribute :number, String
        attribute :phone_type, String
      end

      attribute :id, String
      attribute :title, String
      attribute :preferred_first_name, String
      attribute :first_name, String
      attribute :last_name, String
      attribute :label, String
      attribute :email, String
      attribute :date_of_birth, String
      attribute :gender, String
      attribute :gender_identity, String
      attribute :sex, String
      attribute :time_zone, String

      attribute :address_1, String
      attribute :address_2, String
      attribute :address_3, String
      attribute :city, String
      attribute :post_code, String
      attribute :state, String
      attribute :country, String

      attribute :emergency_contact, String
      attribute :medicare, String
      attribute :medicare_reference_number, String
      attribute :dva_card_number, String
      attribute :occupation, String
      attribute :reminder_type, String
      attribute :notes, String
      attribute :appointment_notes, String

      attribute :invoice_default_to, String
      attribute :invoice_email, String
      attribute :invoice_extra_information, String
      attribute :patient_phone_numbers, Array[PhoneNumber]

      attribute :referral_source, String

      attribute :archived_at, DateTime
      attribute :deleted_at, DateTime
      attribute :created_at, DateTime
      attribute :updated_at, DateTime

      def full_address
        [
          address_1, address_2, city, state, post_code, country
        ].map(&:presence).compact.join(' ')
      end
    end
  end
end
