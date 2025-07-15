json.patients do
  json.array! @patients, partial: 'patients/patient', as: :patient
end
