json.availabilities do
  json.array! @result[:availabilities], partial: 'availabilities/availability', as: :availability
end
json.pagination do
  json.current_page @result[:availabilities].current_page
  json.total_pages @result[:availabilities].total_pages
  json.total_entries @result[:availabilities].total_count
end
json.nearby_practitioners do
  json.array! @result[:nearby_practitioners], partial: 'practitioners/practitioner', as: :practitioner
end
