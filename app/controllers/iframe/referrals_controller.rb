module Iframe
  class ReferralsController < BaseController
    DYNAMIC_PAYMENT_REFERRAL = 'dpr'

    skip_before_action :verify_authenticity_token

    rescue_from ActiveRecord::RecordNotFound do |e|
      respond_to do |f|
        f.html { head :not_found }
      end
    end

    def new
      if params[:business].present? && @business = Business.find(params[:business])
        @available_professions = find_business_available_professions(@business)

        @referral_template = params[:template]

        @referral_form = IframeReferralForm.new(
          business: @business
        )

        if @referral_template.present? && Referral::TYPES.include?(@referral_template)
          @referral_form.type = @referral_template
        end

        practitioner_id = params[:practitioner_id]
        if practitioner_id.present? && @business.practitioners.active.exists?(id: practitioner_id)
          @referral_form.practitioner_id = practitioner_id
        end

        profession = params[:profession]
        if profession.present? && Practitioner::PROFESSIONS.include?(profession)
          @referral_form.professions = [profession]
        end

        availability_type_id = params[:availability_type_id]
        if availability_type_id.present?
          @referral_form.availability_type_id = availability_type_id
        end

        if Referral::TYPES.include?(@referral_template)
          if @referral_template == Referral::TYPE_SELF_REFERRAL
            render :self_referral
          elsif @referral_template == Referral::TYPE_EXPANDED
            render :expanded
          else
            render :payment_referral
          end
        elsif @referral_template == DYNAMIC_PAYMENT_REFERRAL
          render :dynamic_payment_referral
        else
          render :default
        end

      else
        head :not_found
      end
    end

    def create
      @business = Business.find params[:business]
      @referral_form = IframeReferralForm.new(
        referral_params.merge(business: @business)
      )
      @referral_form.patient.referral_type = @referral_form.type

      is_recaptcha_pass = App::RECAPTCHA_ENABLE ? verify_recaptcha : true

      if @referral_form.valid? && is_recaptcha_pass
        CreateReferralService.new.call(@business, @referral_form)

        respond_to do |f|
          f.html { render :success, status: 201 }
          f.json { render json: {}, status: 201 }
        end
      else
        if !is_recaptcha_pass
          @referral_form.errors.add(:base, 'Please complete Captcha correctly')
        end

        respond_to do |f|
          f.html do
            render :default, status: 422
          end
          f.json do
            errors = @referral_form.errors.full_messages + @referral_form.patient.errors.full_messages
            render(
              json: {
                errors: errors
              },
              status: 422
            )
          end
        end
      end
    end

    private

    def referral_params
      params.require(:referral).permit(
        :availability_type_id,
        :practitioner_id,
        :referrer_business_name,
        :referrer_name,
        :referrer_email,
        :referrer_phone,
        :medical_note,
        :priority,
        :referral_reason,
        :type,

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

          # NOK breakdown details
          :nok_name,
          :nok_contact,
          :nok_arrange_appointment,

          # GP details
          :gp_name,
          :gp_contact,
        ],
        professions: [],
        attachments: []
      )
    end

    def find_business_available_professions(business)
      business.practitioners
        .includes(:user)
        .where(user: {is_practitioner: true})
        .active
        .pluck(Arel.sql('DISTINCT profession'))
        .select(&:present?)
    end
  end
end
