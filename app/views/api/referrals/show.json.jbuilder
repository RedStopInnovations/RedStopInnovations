json.referral do
  json.extract! @referral,
                :id,
                :availability_type_id,
                :professions,
                :priority,
                :practitioner_id,
                :patient_id,
                :status,
                :type,
                :referrer_name,
                :referrer_phone,
                :referrer_email,
                :referrer_business_name,
                :patient_attrs,
                :created_at,
                :updated_at

  json.patient do
    if @referral.patient
      json.partial! 'patients/patient', patient: @referral.patient
    end
  end

  json.practitioner do
    if @referral.practitioner
      json.partial! 'practitioners/practitioner', practitioner: @referral.practitioner
    end
  end
end
