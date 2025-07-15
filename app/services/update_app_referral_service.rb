# @TODO: think a different class name
class UpdateAppReferralService
  attr_reader :referral, :referral_form

  # @param ::Referral referral
  # @param ::AppReferralForm referral_form
  def call(referral, referral_form)
    @referral = referral
    @referral_form = referral_form

    ApplicationRecord.transaction do
      update_referral
      store_attachments
    end
  end

  private

  def update_referral
    referral.assign_attributes collect_referral_attributes
    referral.save!(validate: false)

    referral
  end

  def collect_referral_attributes
    attrs = referral_form.attributes.slice(
      :availability_type_id,
      :practitioner_id,
      :professions,
      :notes,
      :priority,
      :referral_reason,
      :referrer_business_name,
      :referrer_name,
      :referrer_email,
      :referrer_phone
    )

    attrs[:patient_attrs] = referral_form.patient.attributes.slice(
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
      :general_info,
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
      :strc_invoice_to_email
    )

    attrs
  end

  def store_attachments
    referral_form.attachments.each do |uploaded_file|
      if uploaded_file.present? && uploaded_file.is_a?(ActionDispatch::Http::UploadedFile)
        attm = referral.attachments.new(
          attachment: uploaded_file
        )

        attm.save!(validate: false)
      end
    end
  end
end
