class CreatePatientMyobAccount < ActiveRecord::Migration[5.0]
  def change
    create_table :patient_myob_accounts do |t|
      t.integer :patient_id, null: :false
      t.string :uid
      t.string :row_version

      t.timestamps

      t.index :patient_id
    end
  end
end
