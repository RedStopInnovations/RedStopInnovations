json.extract!(
  wait_list,
 :id,
 :patient_id,
 :date,
 :created_at,
 :scheduled,
 :practitioner_id,
 :profession,
 :appointment_type_id,
 :repeat_group_uid,
 :notes
)
json.patient do
  json.partial! 'patients/patient', patient: wait_list.patient
end

json.practitioner do
  if wait_list.practitioner
    json.partial! 'practitioners/practitioner', practitioner: wait_list.practitioner
  end
end

json.appointment_type do
  if wait_list.appointment_type
    json.extract!(
      wait_list.appointment_type,
      :id,
      :name,
      :availability_type_id,
      :availability_type,
      :duration,
      :deleted_at
    )
  end
end
