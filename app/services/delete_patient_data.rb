class DeletePatientData
  def call(patient)
    ActiveRecord::Base.transaction do
      patient_id = patient.id
      Invoice.where(patient_id: patient_id).update_all(
        deleted_at: Time.current
      )
      Appointment.where(patient_id: patient_id).update_all(
        deleted_at: Time.current
      )
      Payment.where(patient_id: patient_id).update_all(
        deleted_at: Time.current
      )
      Treatment.where(patient_id: patient_id).delete_all
      PatientLetter.where(patient_id: patient_id).delete_all
      PatientAttachment.where(patient_id: patient_id).delete_all
      PatientContact.where(patient_id: patient_id).delete_all
    end
  end
end
