class AddIsConfirmedToAppointments < ActiveRecord::Migration[6.1]
  def change
    add_column :appointments, :is_confirmed, :boolean, default: false
  end
end
