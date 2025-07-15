module Webhook
  module Patient
    class Serializer

      attr_reader :patient

      def initialize(patient)
        @patient = patient
      end

      def as_json(options = {})
        attrs = patient.attributes.symbolize_keys.slice(
         :id,
         :first_name,
         :last_name,
         :full_name,
         :dob,
         :email,
         :gender,
         :phone,
         :mobile,
         :fax,
         :address1,
         :address2,
         :city,
         :state,
         :postcode,
         :country,
         :reminder_enable,
         :next_of_kin,
         :general_info,
         :medicare_card_number,
         :medicare_card_irn,
         :medicare_referrer_name,
         :medicare_referrer_provider_number,
         :medicare_referral_date,
         :dva_file_number,
         :dva_card_type,
         :dva_referrer_name,
         :dva_referrer_provider_number,
         :dva_referral_date,
         :archived_at,
         :deleted_at,
         :updated_at,
         :created_at
        )
        attrs
      end
    end
  end
end
