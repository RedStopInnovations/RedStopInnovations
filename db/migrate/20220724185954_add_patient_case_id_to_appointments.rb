class AddPatientCaseIdToAppointments < ActiveRecord::Migration[6.1]
  def change
    add_column :appointments, :patient_case_id, :integer
    add_index :appointments, :patient_case_id
  end
end
