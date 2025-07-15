class AddPatientIdToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :patient_id, :integer
  end
end
