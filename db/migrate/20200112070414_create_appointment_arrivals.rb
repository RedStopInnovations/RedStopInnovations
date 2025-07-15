class CreateAppointmentArrivals < ActiveRecord::Migration[5.2]
  def change
    create_table :appointment_arrivals do |t|
      t.integer :appointment_id, null: :false
      t.datetime :sent_at

      t.datetime :arrival_at
      t.decimal :travel_distance, precision: 10, scale: 2
      t.integer :travel_duration

      t.text :error

      t.timestamps

      t.index :appointment_id
    end
  end
end
