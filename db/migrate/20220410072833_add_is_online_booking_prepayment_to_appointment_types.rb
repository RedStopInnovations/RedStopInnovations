class AddIsOnlineBookingPrepaymentToAppointmentTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :appointment_types, :is_online_booking_prepayment, :boolean, default: false
  end
end
