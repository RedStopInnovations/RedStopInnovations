json.appointments do
  json.array! @appointments, partial: 'appointments/appointment', as: :appointment
end
