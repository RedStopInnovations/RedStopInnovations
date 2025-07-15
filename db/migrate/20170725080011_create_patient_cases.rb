class CreatePatientCases < ActiveRecord::Migration[5.0]
  def change
    create_table :patient_cases do |t|
      t.text :notes
      t.string :status
      t.integer :practitioner_id, null: :fasle
      t.integer :case_type_id, null: :false
      t.integer :patient_id, null: :false

      t.index :patient_id
      t.index :case_type_id
      t.index :practitioner_id
      t.timestamps
    end
  end
end
