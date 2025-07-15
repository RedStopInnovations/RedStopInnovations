class AddDisplayOnOnlineBookingsToApptTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :appointment_types, :display_on_online_bookings, :boolean, default: true
  end
end
