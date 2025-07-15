class BillPastAppointmentsJob < ApplicationJob
  APPLY_FROM_DATE = '2017-10-31'

  def perform
    created_from = DateTime.parse APPLY_FROM_DATE

    Appointment.select('appointments.id, appointments.practitioner_id').
      where('appointments.created_at > ?', created_from).
      joins('LEFT JOIN subscription_billings ON subscription_billings.appointment_id = appointments.id').
      where('subscription_billings.id IS NULL').
      where('appointments.start_time < ?', 2.hours.ago).
      includes(practitioner: :business).
      find_each do |appt|
        SubscriptionBillingService.new.bill_appointment(
          appt.practitioner.business,
          appt.id,
          SubscriptionBilling::TRIGGER_TYPE_OCCURRED
        )
      end
  end
end
