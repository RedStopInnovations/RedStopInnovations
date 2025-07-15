class ApproveReferralService
  attr_reader :business, :referral

  def call(business, referral)
    @business = business
    @referral = referral

    patient = nil

    ApplicationRecord.transaction do
      patient = build_patient
      patient.save!

      referral.attachments.each do |attm|
        patient.attachments.create attachment: attm.attachment
      end

      referral.assign_attributes(
        status: Referral::STATUS_APPROVED,
        business_id: business.id,
        patient_id: patient.id,
        approved_at: Time.current,
        reject_reason: nil,
        rejected_at: nil
      )

      referral.save!(validate: false)
    end

    ::Webhook::Worker.perform_later(patient.id, WebhookSubscription::PATIENT_CREATED)
  end

  private

  def build_patient
    patient = business.patients.new(referral.patient_attrs)

    patient.general_info = "#{patient.general_info}\n\n" << build_client_general_info
    patient.general_info.strip!

    unless patient.country.present?
      patient.country = business.country
    end

    patient
  end

  def build_client_general_info
    lines = []

    if referral.medical_note.present?
      lines << "Relevant medical history: #{referral.medical_note.strip}\n"
    end

    if referral.referral_reason.present?
      lines << "Reason for referral: #{referral.referral_reason.strip}\n"
    end

    lines.join("\n")
  end
end
