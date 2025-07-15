class CreatePatientAttachments < ActiveRecord::Migration[5.0]
  def change
    create_table :patient_attachments do |t|
      t.integer :patient_id, null: false
      t.attachment :attachment
      t.text :description
      t.timestamps

      t.index :patient_id
    end
  end
end
