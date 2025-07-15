json.extract! appointment, :id, :start_time, :end_time, :appointment_type_id, :patient_id, :practitioner_id, :notes, :availability_id, :is_completed, :booked_online, :order, :break_times, :status, :is_confirmed, :patient_case_id, :created_at
json.start_time_ts appointment.start_time.to_i

if appointment.bookings_answers
  json.bookings_answers appointment.bookings_answers.as_json(include: [:question])
end

json.patient do
  json.partial! 'patients/patient', patient: appointment.patient
end
json.appointment_type do
  json.extract! appointment.appointment_type, :id, :name, :availability_type_id, :availability_type, :duration, :color, :deleted_at
end
json.practitioner do
  json.partial! 'practitioners/practitioner', practitioner: appointment.practitioner
end
json.invoice do
  if appointment.invoice
    json.partial! 'invoices/invoice', invoice: appointment.invoice
  end
end
json.treatment do
  if appointment.treatment
    json.partial! 'treatments/treatment', treatment: appointment.treatment
  end
end

if appointment.home_visit? || appointment.facility? || appointment.group_appointment?
  json.arrival do
    if appointment.arrival
      json.extract! appointment.arrival, :arrival_at, :travel_duration, :error, :sent_at
      json.set! :travel_distance, appointment.arrival.travel_distance.to_f # Cast to float
    end
  end
end