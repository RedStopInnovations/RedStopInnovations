json.practitioners do
  json.array! @practitioners, partial: 'api/practitioners/practitioner', as: :practitioner
end
