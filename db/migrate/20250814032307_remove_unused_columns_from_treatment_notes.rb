class RemoveUnusedColumnsFromTreatmentNotes < ActiveRecord::Migration[7.1]
  def change
    remove_column :treatment_notes, :practitioner_id
    remove_column :treatment_notes, :print_name
    remove_column :treatment_notes, :print_address
    remove_column :treatment_notes, :print_birth
    remove_column :treatment_notes, :print_ref_num
    remove_column :treatment_notes, :print_doctor
    remove_column :treatment_notes, :sections
  end
end
