class UpdatePatientAccessService
  attr_reader :patient

  def call(patient, form_request)
    result = OpenStruct.new
    @patient = patient
    @business = patient.business
    result.patient_id = patient.id
    user_ids = form_request[:user_ids].to_a
    user_ids ||= []

    if user_ids.empty?
      PatientAccess.where(
        patient_id: patient.id
      ).delete_all
    else
      current_granted_user_ids =
        PatientAccess.where(patient_id: patient.id).pluck(:user_id)

      granted_user_ids =
        @business.users.not_role_administrator.where(id: user_ids).pluck(:id)
      result.user_ids = granted_user_ids

      new_granted_user_ids = granted_user_ids - current_granted_user_ids

      # Remove no longer access
      PatientAccess.
        where(patient_id: patient.id).
        where.not(user_id: granted_user_ids).
        delete_all

      # Add new access
      PatientAccess.create(
        new_granted_user_ids.map do |user_id|
          {
            patient_id: patient.id,
            user_id: user_id
          }
        end
      )
    end
    result.success = true
    result
  end
end
