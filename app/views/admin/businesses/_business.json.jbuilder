json.extract! business, :id, :name, :phone, :mobile, :website, :email, :avatar, :full_address

json.practitioners do
  json.array! business.practitioners, partial: 'practitioners/practitioner', as: :practitioner
end

json.patients do
  json.array! business.patients, partial: 'patients/patient', as: :patient
end

json.appointment_types do
  json.array! business.appointment_types
end
