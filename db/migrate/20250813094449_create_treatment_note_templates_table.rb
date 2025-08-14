class CreateTreatmentNoteTemplatesTable < ActiveRecord::Migration[7.1]
  def change
    create_table :treatment_note_templates do |t|
      t.integer :business_id, null: false, index: true
      t.string :name, null: false
      t.text :content
      t.text :html_content

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
