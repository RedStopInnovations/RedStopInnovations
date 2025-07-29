class RemovePrepaymentFromApptTpes < ActiveRecord::Migration[7.1]
  def change
    remove_column :appointment_types, :is_online_booking_prepayment, :boolean, default: false
  end
end
