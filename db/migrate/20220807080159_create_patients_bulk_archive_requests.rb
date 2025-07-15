class CreatePatientsBulkArchiveRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :patient_bulk_archive_requests do |t|
      t.integer :business_id, null: false, index: true
      t.integer :author_id, null: false
      t.text :description

      t.json :filters # Criteria

      t.integer :archived_patients_count # Number of patients processed

      t.string :status, null: false # Process status

      t.timestamps
    end
  end
end
