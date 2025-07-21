json.doctor_contacts do
  json.array! @patient.doctor_contacts, partial: 'api/contacts/contact', as: :contact
end

json.specialist_contacts do
  json.array! @patient.specialist_contacts, partial: 'api/contacts/contact', as: :contact
end

json.referrer_contacts do
  json.array! @patient.referrer_contacts, partial: 'api/contacts/contact', as: :contact
end

json.invoice_to_contacts do
  json.array! @patient.invoice_to_contacts, partial: 'api/contacts/contact', as: :contact
end

json.emergency_contacts do
  json.array! @patient.emergency_contacts, partial: 'api/contacts/contact', as: :contact
end

json.other_contacts do
  json.array! @patient.other_contacts, partial: 'api/contacts/contact', as: :contact
end
