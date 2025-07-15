class CreatePatientLetters < ActiveRecord::Migration[5.0]
  def change
    create_table :patient_letters do |t|
      t.integer :patient_id, null: false
      t.integer :letter_template_id, null: false

      t.integer :business_id, null: false
      t.integer :author_id

      t.string :description
      t.text :content

      t.timestamps
      t.index :patient_id
      t.index :business_id
      t.index :letter_template_id
    end
  end
end
