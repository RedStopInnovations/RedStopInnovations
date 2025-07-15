json.extract! availability, :id, :business_id, :name, :start_time, :end_time,
             :max_appointment, :service_radius, :full_address, :short_address,
             :address1, :address2, :city, :state, :postcode, :country,
             :latitude, :longitude, :allow_online_bookings, :updated_at, :created_at,
             :recurring_id, :availability_type_id, :availability_type,
             :practitioner_id, :appointments_count, :contact_id, :description, :order_locked,
             :order_locked_by, :routing_status, :availability_subtype_id, :group_appointment_type_id, :cached_stats

json.set! :driving_distance, availability.driving_distance.to_f
json.set! :appointments do
  json.array! availability.appointments, partial: 'appointments/appointment', as: :appointment
end

json.set! :practitioner do
  json.partial! 'practitioners/practitioner', practitioner: availability.practitioner
end

if availability.contact
  json.set! :contact do
    json.partial! 'api/contacts/contact', contact: availability.contact
  end
end

if availability.respond_to?(:distance)
  json.distance availability.distance
end

json.set! :availability_subtype do
  if availability.availability_subtype
    json.extract! availability.availability_subtype, :id, :name
  end
end

json.set! :group_appointment_type do
  if availability.group_appointment_type
    json.extract! availability.group_appointment_type,  :id, :name, :availability_type_id, :availability_type, :duration, :color, :deleted_at
  end
end
