json.extract! appointment, :id, :start_time, :end_time, :appointment_type_id, :patient_id, :practitioner_id, :notes, :availability_id, :is_completed, :booked_online, :order, :break_times, :status, :is_confirmed

json.appointment_type do
  json.extract! appointment.appointment_type, :id, :name, :availability_type_id, :availability_type, :duration, :color, :deleted_at
end

json.practitioner do
  json.partial! 'practitioners/practitioner', practitioner: appointment.practitioner
end