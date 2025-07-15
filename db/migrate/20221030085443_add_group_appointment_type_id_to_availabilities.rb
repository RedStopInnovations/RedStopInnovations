class AddGroupAppointmentTypeIdToAvailabilities < ActiveRecord::Migration[6.1]
  def change
    add_column :availabilities, :group_appointment_type_id, :integer
  end
end
