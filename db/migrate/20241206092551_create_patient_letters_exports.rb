class CreatePatientLettersExports < ActiveRecord::Migration[7.1]
  def change
    create_table :patient_letters_exports do |t|
      t.integer :business_id, null: false, index: true
      t.integer :author_id, null: false, index: true
      t.json :options
      t.text :description
      t.string :status, null: false
      t.timestamps
    end
  end
end
