class CreatePatientStatements < ActiveRecord::Migration[5.0]
  def change
    create_table :patient_statements do |t|
      t.integer :patient_id
      t.date :start_date
      t.date :end_date
      t.string :number

      t.timestamps

      t.index :patient_id
    end
  end
end
