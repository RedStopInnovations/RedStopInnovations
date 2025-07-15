module Api
  module V1
    class PatientSerializer < BaseSerializer
      type 'patients'

      attributes :first_name,
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
                 :next_of_kin,
                 :general_info,
                 :accepted_privacy_policy,
                 :aboriginal_status,
                 :nationality,
                 :spoken_languages,
                 :reminder_enable,
                 :important_notification,

                 # medicare_details
                 :medicare_card_number,
                 :medicare_card_irn,
                 :medicare_referrer_name,
                 :medicare_referrer_provider_number,
                 :medicare_referral_date,

                 # dva_details
                 :dva_file_number,
                 :dva_card_type,
                 :dva_referrer_name,
                 :dva_referrer_provider_number,
                 :dva_referral_date,

                 # NDIS details
                 :ndis_client_number,
                 :ndis_plan_start_date,
                 :ndis_plan_end_date,
                 :ndis_plan_manager_name,
                 :ndis_plan_manager_phone,
                 :ndis_plan_manager_email,

                 # Home care package details
                 :hcp_company_name,
                 :hcp_manager_name,
                 :hcp_manager_phone,
                 :hcp_manager_email,

                 # Hospital in the home details
                 :hih_hospital,
                 :hih_procedure,
                 :hih_discharge_date,
                 :hih_surgery_date,
                 :hih_doctor_name,
                 :hih_doctor_phone,
                 :hih_doctor_email,

                 # Health insurance details
                 :hi_company_name,
                 :hi_number,
                 :hi_manager_name,
                 :hi_manager_email,
                 :hi_manager_phone,

                 # STRC details
                 :strc_company_name,
                 :strc_company_phone,
                 :strc_invoice_to_name,
                 :strc_invoice_to_email,

                 :archived_at,
                 :deleted_at,
                 :updated_at,
                 :created_at

      has_many :appointments do
        link :self do
          @url_helpers.api_v1_patient_appointments_url(@object.id)
        end
      end

      has_many :attachments do
        link :self do
          @url_helpers.api_v1_patient_attachments_url(@object.id)
        end
      end

      has_many :contact_associations do
        link :self do
          @url_helpers.api_v1_patient_contact_associations_url(@object.id)
        end
      end

      link :self do
        @url_helpers.api_v1_patient_url(@object.id)
      end
    end
  end
end
