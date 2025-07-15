class FindDuplicatePatientsService
  def call(business, patient)
    @business = business
    @patient = patient
    find_patients_has_same_name
  end

  private

  def find_patients_has_same_name
    @business.patients.where(
      "LOWER(full_name) LIKE :full_name",
      full_name: "%#{@patient.full_name.downcase.strip}%",
      ).
      order(id: :asc).
      where('patients.id <> ?', @patient.id).
      to_a
  end
end
