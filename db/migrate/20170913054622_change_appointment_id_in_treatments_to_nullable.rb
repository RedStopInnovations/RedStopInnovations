class ChangeAppointmentIdInTreatmentsToNullable < ActiveRecord::Migration[5.0]
  def change
    change_column :treatments, :appointment_id, :integer, null: true
  end
end
