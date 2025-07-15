class AddCreatedAtIndexToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_index :appointments, :created_at
  end
end
