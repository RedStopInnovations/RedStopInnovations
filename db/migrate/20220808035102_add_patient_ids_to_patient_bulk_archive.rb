class AddPatientIdsToPatientBulkArchive < ActiveRecord::Migration[6.1]
  def change
    add_column :patient_bulk_archive_requests, :archived_patient_ids, :text
  end
end
