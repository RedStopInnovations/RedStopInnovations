class AddAvailabiliyIdToAppointments < ActiveRecord::Migration[5.0]
  def change
    add_column :appointments, :availability_id, :integer
  end
end
