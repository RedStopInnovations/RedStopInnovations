module Api
  module V1
    class ReferralsController < V1::BaseController
      before_action :find_referal, only: [:show]

      def index
        referrals = current_business.
          referrals.
          order(id: :asc).
          ransack(jsonapi_filter_params).
          result.
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: referrals, meta: pagination_meta(referrals)
      end

      def show
        render jsonapi: @referal
      end

      def create
        referral_form = Api::V1::CreateReferralForm.new(
          create_referral_params.merge(business: current_business)
        )

        if referral_form.valid?
          referral = Api::V1::CreateReferralService.new.call(current_business, referral_form)

          render jsonapi: referral, status: 201
        else
          errors = referral_form.errors
          render jsonapi_errors: referral_form.errors, status: 422
        end
      end

      private

      def find_referal
        @referal = current_business.referrals.find(params[:id])
      end

      def create_referral_params
        params.permit(
          :referral_type,
          :availability_type,
          :practitioner_id,
          :priority,

          :referrer_business_name,
          :referrer_name,
          :referrer_email,
          :referrer_phone,

          :medical_note,
          :referral_reason,

          patient: [
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
            :general_info,

            # Medicare details
            :medicare_card_number,
            :medicare_card_irn,
            :medicare_referrer_name,
            :medicare_referrer_provider_number,
            :medicare_referral_date,

            # DVA details
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

            # NOK details breakdown
            :nok_name,
            :nok_contact,
            :nok_arrange_appointment,

            # GP details breakdown
            :gp_name,
            :gp_contact
          ],
          professions: []
        )
      end

      def jsonapi_whitelist_filter_params
        [
          :id_eq,

          :referrer_business_name_eq,
          :referrer_business_name_cont,

          :referrer_name_eq,
          :referrer_name_cont,

          :referrer_email_cont,
          :referrer_phone_cont,

          :status_eq,
          :status_in,

          :created_at_lt,
          :created_at_lteq,
          :created_at_gt,
          :created_at_gteq,

          :updated_at_lt,
          :updated_at_lteq,
          :updated_at_gt,
          :updated_at_gteq
        ]
      end
    end
  end
end
