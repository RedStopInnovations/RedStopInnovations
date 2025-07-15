class AddBookedOnlineFlagToAppointments < ActiveRecord::Migration[5.0]
  def change
    add_column :appointments, :booked_online, :boolean, null: false, default: false
  end
end
