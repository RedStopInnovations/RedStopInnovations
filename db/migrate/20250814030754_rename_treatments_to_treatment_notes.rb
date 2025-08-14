class RenameTreatmentsToTreatmentNotes < ActiveRecord::Migration[7.1]
  def change
    rename_table :treatments, :treatment_notes
  end
end
