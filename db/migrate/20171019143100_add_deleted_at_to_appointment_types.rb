class AddDeletedAtToAppointmentTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :appointment_types, :deleted_at, :datetime
  end
end
