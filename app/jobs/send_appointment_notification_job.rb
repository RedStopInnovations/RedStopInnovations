class SendAppointmentNotificationJob < ApplicationJob
  def perform(appointment_id, notification_type_id)
    AppointmentNotificationService.new.call(
      Appointment.unscoped.find(appointment_id),
      notification_type_id
    )
  end
end
