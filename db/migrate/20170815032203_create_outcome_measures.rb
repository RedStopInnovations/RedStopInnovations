class CreateOutcomeMeasures < ActiveRecord::Migration[5.0]
  def change
    create_table :outcome_measures do |t|
      t.integer :patient_id, null: false
      t.integer :outcome_measure_type_id, null: false
      t.integer :practitioner_id, null: false
      t.timestamps
    end
  end
end
