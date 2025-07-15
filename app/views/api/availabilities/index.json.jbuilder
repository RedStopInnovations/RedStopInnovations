json.availabilities do
  json.array! @availabilities, partial: 'availabilities/availability', as: :availability
end
