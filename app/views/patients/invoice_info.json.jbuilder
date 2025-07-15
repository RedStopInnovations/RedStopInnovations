json.invoice_to_contacts @patient_presenter.invoice_to
json.cases @patient_presenter.cases
json.pricing_contacts @patient_presenter.pricing_contacts
json.appointments do
  json.array! @patient.appointments.includes(practitioner: :user) do |appt|
    json.extract! appt, :id, :start_time, :end_time, :appointment_type_id, :patient_id, :practitioner_id, :notes, :availability_id, :is_completed, :booked_online, :order, :break_times, :status
    json.practitioner do
      json.partial! 'practitioners/practitioner', practitioner: appt.practitioner
    end
  end
end
