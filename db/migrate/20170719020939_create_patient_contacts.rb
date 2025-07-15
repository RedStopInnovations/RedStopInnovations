class CreatePatientContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :patient_contacts do |t|
      t.integer :patient_id, null: false
      t.integer :contact_id, null: false
      t.string :type
      t.boolean :primary, default: false

      t.index :patient_id
      t.index :contact_id
      t.index [:patient_id, :type]

      t.timestamps
    end
  end
end
