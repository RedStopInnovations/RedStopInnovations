json.patient_case do
  json.partial! 'api/patient_cases/patient_case', patient_case: @patient_case
end