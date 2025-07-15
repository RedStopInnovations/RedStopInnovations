json.contacts do
  json.array! @contacts, partial: 'api/contacts/contact', as: :contact
end
