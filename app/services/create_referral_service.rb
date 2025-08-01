class CreateReferralService
  attr_reader :business, :referral_form

  def call(business, referral_form)
    @business = business
    @referral_form = referral_form

    referral = nil
    ApplicationRecord.transaction do
      referral = create_referral
      store_attachments(referral)
      referral.businesses.push(@business)
    end

    if referral
      if business.email?
        BusinessMailer.new_referral(referral, business).deliver_later
      end

      if referral.referrer_email?
        ReferralMailer.referral_confirmation(referral).deliver_later
      end
    end
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
      :type,
      :availability_type_id,
      :practitioner_id,
      :professions,
      :medical_note,
      :priority,
      :referral_reason,
      :referrer_business_name,
      :referrer_name,
      :referrer_phone,
      :referrer_email
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

    if referral_form.patient.nok_name
      attrs[:patient_attrs][:next_of_kin] = "#{attrs[:patient_attrs][:next_of_kin]}\n" << build_nok_details
      attrs[:patient_attrs][:next_of_kin].strip!
    end

    if referral_form.patient.gp_name
      attrs[:patient_attrs][:general_info] = "GP details: \n" << build_gp_details
      attrs[:patient_attrs][:general_info].strip!
    end

    attrs
  end

  def store_attachments(referral)
    referral_form.attachments.each do |uploaded_file|
      attm = referral.attachments.new(
        attachment: uploaded_file
      )

      attm.save!(validate: false)
    end
  end

  def build_nok_details
    [
      "Name: #{referral_form.patient.nok_name}",
      "Contact: #{referral_form.patient.nok_contact}",
      "Contact NOK to arrange appointment?: #{referral_form.patient.nok_arrange_appointment}",
    ].join("\n")
  end

  def build_gp_details
    [
      "Name: #{referral_form.patient.gp_name}",
      "Contact: #{referral_form.patient.gp_contact}",
    ].join("\n")
  end
end
