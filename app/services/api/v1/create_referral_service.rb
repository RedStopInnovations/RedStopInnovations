module Api
  module V1
    class CreateReferralService
      attr_reader :business, :referral_form

      # @param Business business
      # @param Api::V1::CreateReferralForm referral_form
      def call(business, referral_form)
        @business = business
        @referral_form = referral_form

        referral = nil

        ApplicationRecord.transaction do
          referral = create_referral
          referral.businesses.push(@business)
        end

        referral
      end

      private

      def create_referral
        referral = Referral.new(
          business_id: business.id,
          status: Referral::STATUS_PENDING
        )
        referral.assign_attributes collect_referral_attributes
        referral.save!(validate: false)

        referral
      end

      def collect_referral_attributes
        attrs = referral_form.attributes.slice(
          :practitioner_id,
          :professions,
          :priority,
          :referral_reason,
          :medical_note,
          :referrer_business_name,
          :referrer_name,
          :referrer_email,
          :referrer_phone
        )

        attrs[:availability_type_id] = ::AvailabilityType::find_by_uid(referral_form.availability_type).id
        attrs[:type] = referral_form.referral_type

        patient_attrs = referral_form.patient.attributes.slice(
          :first_name,
          :last_name,
          :dob,
          :phone,
          :mobile,
          :email,
          :address1,
          :city,
          :state,
          :postcode,
          :country,
          :aboriginal_status,
          :next_of_kin,
          :general_info
        )

        case referral_form.referral_type
          when ::Referral::TYPE_DVA
            patient_attrs.merge!(referral_form.patient.attributes.slice(
              # DVA details
              :dva_file_number,
              :dva_card_type,
              :dva_referrer_name,
              :dva_referrer_provider_number,
              :dva_referral_date
            ))
          when ::Referral::TYPE_MEDICARE
            patient_attrs.merge!(referral_form.patient.attributes.slice(
              # Medicare details
              :medicare_card_number,
              :medicare_card_irn,
              :medicare_referrer_name,
              :medicare_referrer_provider_number,
              :medicare_referral_date
            ))
          when ::Referral::TYPE_HCP
            patient_attrs.merge!(referral_form.patient.attributes.slice(
              # Home care package details
              :hcp_company_name,
              :hcp_manager_name,
              :hcp_manager_phone,
              :hcp_manager_email
            ))
          when ::Referral::TYPE_NDIS
            patient_attrs.merge!(referral_form.patient.attributes.slice(
              # NDIS details
              :ndis_client_number,
              :ndis_plan_start_date,
              :ndis_plan_end_date,
              :ndis_plan_manager_name,
              :ndis_plan_manager_phone,
              :ndis_plan_manager_email
            ))
          when ::Referral::TYPE_PRIVATE
            patient_attrs.merge!(referral_form.patient.attributes.slice(
              # Health insurance details
              :hi_company_name,
              :hi_number,
              :hi_manager_name,
              :hi_manager_email,
              :hi_manager_phone
            ))
          when ::Referral::TYPE_HIH
            patient_attrs.merge!(referral_form.patient.attributes.slice(
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
              :hi_manager_phone
            ))
          when ::Referral::TYPE_STRC
            patient_attrs.merge!(referral_form.patient.attributes.slice(
              # STRC details
              :strc_company_name,
              :strc_company_phone,
              :strc_invoice_to_name,
              :strc_invoice_to_email
            ))
        end

        unless patient_attrs[:country].present?
          patient_attrs[:country] = business.country
        end

        attrs[:patient_attrs] = patient_attrs

        attrs
      end
    end
  end
end