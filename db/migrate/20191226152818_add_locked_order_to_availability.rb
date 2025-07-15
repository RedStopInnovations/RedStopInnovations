class AddLockedOrderToAvailability < ActiveRecord::Migration[5.0]
  def change
    add_column :availabilities, :order_locked, :boolean, default: false
    add_column :availabilities, :order_locked_by, :integer
  end
end
