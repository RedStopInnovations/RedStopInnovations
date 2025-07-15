class AddBreakTimesToAppointments < ActiveRecord::Migration[5.0]
  def change
    add_column :appointments, :break_times, :integer
  end
end
