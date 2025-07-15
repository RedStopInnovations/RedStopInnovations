class FindPractitionersReferralService
  attr_reader :referral

  def call(referral)
    business = referral.business
    query = business.practitioners

    if referral.professions.present?
      query = query.where(profession: referral.professions)
    end

    if referral.professions.present?
      query = query.where(profession: referral.professions)
    end

    patient_address = referral.patient_address

    if patient_address
      patient_address_coords = Geocoder.coordinates patient_address
      query = query.near(patient_address_coords, 50, unit: :km)
    end

    query.limit(10).load
  end
end