json.appointment_type do
  json.partial! 'api/appointment_types/appointment_type', appointment_type: @appointment_type
end