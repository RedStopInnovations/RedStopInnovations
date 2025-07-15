class AddOrderAppointments < ActiveRecord::Migration[5.0]
  def change
    add_column :appointments, :order, :integer, default: 0
  end
end
