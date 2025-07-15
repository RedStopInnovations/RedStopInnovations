class CreatePatientAccesses < ActiveRecord::Migration[5.0]
  def change
    create_table :patient_accesses do |t|
      t.integer :patient_id, null: false
      t.integer :user_id, null: false

      t.index :patient_id
      t.index :user_id
    end
  end
end
