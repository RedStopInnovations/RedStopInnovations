class CreatePractitionerDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :practitioner_documents do |t|
      t.integer :practitioner_id, null: false, index: true
      t.string :type, null: false
      t.string :document, null: false
      t.string :document_original_filename, null: false
      t.date :expiry_date
      t.timestamps
    end
  end
end
