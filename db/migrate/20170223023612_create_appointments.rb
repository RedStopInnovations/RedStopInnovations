class CreateAppointments < ActiveRecord::Migration[5.0]
  def change
    create_table :appointments do |t|
      t.references :practitioner, null: false
      t.references :patient, null: false
      t.references :appointment_type, null: false

      t.datetime :start_time
      t.datetime :end_time
      t.text :notes

      t.timestamps
    end
  end
end
