json.extract!(
  practitioner,
  :id, :first_name, :last_name, :full_name, :profession, :phone, :mobile,
  :full_address, :color, :address1, :address2, :city, :state, :postcode, :country,
  :profile_picture_url, :allow_online_bookings, :latitude, :longitude, :medicare, :user_id
)
json.short_address practitioner.short_address
json.email practitioner.user_email
json.timezone practitioner.user_timezone
if practitioner.respond_to?(:distance)
  json.distance practitioner.distance
end
json.profile_picture do
  json.original practitioner.profile_picture_url
  json.medium practitioner.profile_picture_url(:medium)
  json.thumb practitioner.profile_picture_url(:thumb)
end
json.business_hours do
  json.array! practitioner.business_hours, :day_of_week, :active, :availability
end