class CreateAppointmentArrivalTimes < ActiveRecord::Migration[5.0]
  def change
    create_table :appointment_arrival_times do |t|
      t.integer :appointment_id, null: :false
      t.datetime :arrival_at
      t.text :error

      t.timestamps
      
      t.index :appointment_id
    end
  end
end
