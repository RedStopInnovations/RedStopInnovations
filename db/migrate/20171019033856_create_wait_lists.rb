class CreateWaitLists < ActiveRecord::Migration[5.0]
  def change
    create_table :wait_lists do |t|
      t.integer :business_id, null: false
      t.integer :patient_id, null: false
      t.integer :practitioner_id
      t.date    :date, null: false
      t.string  :profession
      t.integer :appointment_type_id
      t.string  :repeat_group_uid
      t.boolean :scheduled, null: false, default: false

      t.index :business_id
      t.index :patient_id
      t.index :practitioner_id
      t.timestamps
    end
  end
end
