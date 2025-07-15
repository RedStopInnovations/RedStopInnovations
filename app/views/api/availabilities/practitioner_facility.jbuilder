json.availabilities @availabilities do |avail|
  json.extract! avail, :id, :business_id, :start_time, :end_time,
           :max_appointment, :service_radius, :full_address, :short_address,
           :address1, :address2, :city, :state, :postcode, :country,
           :latitude, :longitude, :allow_online_bookings, :updated_at, :created_at,
           :availability_type_id, :practitioner_id, :appointments_count
end

json.current_page @availabilities.current_page
json.total_pages @availabilities.total_pages
json.total_entries @availabilities.total_count
