class AddAvailabilityIndexToAppointmentsTable < ActiveRecord::Migration[7.0]
  def change
    add_index :appointments, :availability_id
  end
end
