class AddPatientIdIndexToTreatments < ActiveRecord::Migration[7.1]
  def change
    add_index :treatments, :patient_id
  end
end
