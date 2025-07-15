json.appointment_types do
  json.array! @appointment_types, partial: 'api/appointment_types/appointment_type', as: :appointment_types
end