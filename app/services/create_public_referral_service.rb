class CreatePublicReferralService
  attr_reader :referral_form

  def call(referral_form)
    @referral_form = referral_form

    referral = nil

    ApplicationRecord.transaction do
      referral = create_referral
      store_attachments(referral)
      send_notifications(referral)
    end

    referral
  end

  private

  def create_referral
    referral = Referral.new(
      type: Referral::TYPE_GENERAL,
      status: Referral::STATUS_PENDING
    )

    referral.assign_attributes referral_form.attributes.slice(
      :availability_type_id,
      :medical_note,
      :referrer_business_name,
      :referrer_name,
      :referrer_email,
      :referrer_phone
    )

    referral.professions = [referral_form.profession]

    referral[:patient_attrs] = referral_form.patient.attributes.slice(
      :first_name,
      :last_name,
      :dob,
      :phone,
      :email,
      :address1,
      :city,
      :state,
      :postcode,
      :country
    )

    business = practitioner = nil
    if referral_form.practitioner_id.present?
      practitioner = Practitioner.find_by id: referral_form.practitioner_id
      if practitioner
        business = practitioner.business
        referral.practitioner_id = practitioner.id
        referral.business_id = business.id
      end
    end

    referral.save!(validate: false)

    if business
      referral.businesses.push(business)
    end

    referral
  end

  def store_attachments(referral)
    referral_form.attachments.each do |uploaded_file|
      attm = referral.attachments.new(
        attachment: uploaded_file
      )

      attm.save!(validate: false)
    end
  end

  def send_notifications(referral)
    unless referral.practitioner
      AdminMailer.new_referral(referral).deliver_later
    end

    if referral.referrer_email.present?
      ReferralMailer.referral_confirmation(referral).deliver_later
    end
  end
end
