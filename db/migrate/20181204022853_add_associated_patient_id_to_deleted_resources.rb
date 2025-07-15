class AddAssociatedPatientIdToDeletedResources < ActiveRecord::Migration[5.0]
  def change
    add_column :deleted_resources, :associated_patient_id, :integer
  end
end
