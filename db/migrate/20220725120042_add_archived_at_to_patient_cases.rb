class AddArchivedAtToPatientCases < ActiveRecord::Migration[6.1]
  def change
    add_column :patient_cases, :archived_at, :datetime, index: true
  end
end
