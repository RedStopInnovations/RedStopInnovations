class AddIsCompletedToAppointments < ActiveRecord::Migration[5.0]
  def change
    add_column :appointments, :is_completed, :boolean, default: false
  end
end
