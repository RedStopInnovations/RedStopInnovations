class AddReminderEnableToPatientsAndAppointments < ActiveRecord::Migration[5.0]
  def change
    add_column :appointment_types, :reminder_enable, :boolean, default: true
    add_column :patients, :reminder_enable, :boolean, default: true
  end
end
