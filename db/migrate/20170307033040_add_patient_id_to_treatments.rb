class AddPatientIdToTreatments < ActiveRecord::Migration[5.0]
  def change
    add_column :treatments, :patient_id, :integer
  end
end
