class AddColorToAppointmentTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :appointment_types, :color, :string
  end
end
