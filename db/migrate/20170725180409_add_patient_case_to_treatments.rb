class AddPatientCaseToTreatments < ActiveRecord::Migration[5.0]
  def change
    add_column :treatments, :patient_case_id, :integer
    add_index :treatments, :patient_case_id
  end
end
