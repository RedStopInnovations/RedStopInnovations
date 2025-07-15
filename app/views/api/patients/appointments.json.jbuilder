json.appointments do
  json.array! @appointments, partial: 'api/appointments/appointment', as: :appointment
end