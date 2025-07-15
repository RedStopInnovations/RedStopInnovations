class CreatePatientIdNumbers < ActiveRecord::Migration[5.0]
  def change
    create_table :patient_id_numbers do |t|
      t.integer :patient_id, null: :false
      t.integer :contact_id, null: :false

      t.string :id_number

      t.timestamps

      t.index :patient_id
      t.index :contact_id
    end
  end
end
