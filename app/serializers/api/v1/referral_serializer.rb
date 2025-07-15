module Api
  module V1
    class ReferralSerializer < BaseSerializer
      type 'referrals'

      attributes  :status,
                  :priority,
                  :professions,
                  :internal_note,
                  :referral_reason,
                  :reject_reason,
                  :medical_note,

                  :contact_referrer_date,
                  :contact_patient_date,
                  :first_appoinment_date,
                  :send_treatment_plan_date,
                  :receive_referral_date,
                  :summary_referral,

                  :referrer_business_name,
                  :referrer_name,
                  :referrer_email,
                  :referrer_phone,

                  :updated_at,
                  :created_at,
                  :archived_at,
                  :approved_at,
                  :rejected_at

      belongs_to :practitioner do
        if @object.practitioner
          link :self do
            @url_helpers.api_v1_practitioner_url(@object.practitioner_id)
          end
        end
      end

      has_many :attachments do
        link :self do
          @url_helpers.api_v1_referral_attachments_url(@object.id)
        end
      end

      attribute :patient do
        @object.patient_attrs
      end

      attribute :availability_type do
        if @object.availability_type_id.present?
          ::AvailabilityType[@object.availability_type_id]&.uid
        end
      end

      attribute :referral_type do
        @object.type.presence || ::Referral::TYPE_GENERAL
      end

      link :self do
        @url_helpers.api_v1_referral_url(@object.id)
      end
    end
  end
end
