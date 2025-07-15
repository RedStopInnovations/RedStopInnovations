class AddAllowOnlineBookingsToAvailabilities < ActiveRecord::Migration[5.0]
  def change
    add_column :availabilities, :allow_online_bookings, :boolean, default: true, null: false
    add_index :availabilities, :allow_online_bookings
  end
end
