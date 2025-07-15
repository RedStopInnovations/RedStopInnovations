class AddAllowOnlineBookingsToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :allow_online_bookings, :boolean, default: true, index: true
  end
end
