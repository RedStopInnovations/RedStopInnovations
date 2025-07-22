class CreatePatientTags < ActiveRecord::Migration[7.1]
  def change
    create_table :patients_tags do |t|
      t.references :patient, null: false
      t.references :tag, null: false

      t.timestamps
    end

    add_index :patients_tags, [:patient_id, :tag_id], unique: true
  end
end
