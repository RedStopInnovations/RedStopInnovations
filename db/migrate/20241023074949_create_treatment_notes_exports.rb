class CreateTreatmentNotesExports < ActiveRecord::Migration[7.1]
  def change
    create_table :treatment_notes_exports do |t|
      t.integer :business_id, null: false, index: true
      t.integer :author_id, null: false, index: true
      t.json :options
      t.text :description
      t.string :status, null: false
      t.timestamps
    end
  end
end
