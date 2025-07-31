json.associated_contacts do
  json.array! @associated_contacts do |patient_contact|
    json.extract! patient_contact, :id, :contact_id, :patient_id, :type, :for_appointments, :for_invoices, :for_treatment_notes, :created_at, :updated_at
    json.contact patient_contact.contact, partial: 'api/contacts/contact', as: :contact
  end
end