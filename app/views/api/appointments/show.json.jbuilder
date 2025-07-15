json.appointment do
  json.partial! 'appointments/appointment', appointment: @appointment
end
