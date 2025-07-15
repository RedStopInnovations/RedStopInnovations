class CreateCommunications < ActiveRecord::Migration[5.0]
  def change
    create_table :communications do |t|
      t.string :message_type
      t.string :category
      t.string :direction
      t.integer :patient_id, null: false
      t.integer :practitioner_id, null: false
      t.string :message

      t.timestamps
      t.index :patient_id
      t.index :practitioner_id
      t.index [:practitioner_id, :patient_id]
    end
  end
end
