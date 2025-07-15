class AddCancelledByIdToAppointments < ActiveRecord::Migration[6.1]
  def change
    add_column :appointments, :cancelled_by_id, :integer
  end
end
