json.patient_cases do
  json.array! @patient_cases, partial: 'api/patient_cases/patient_case', as: :patient_case
end