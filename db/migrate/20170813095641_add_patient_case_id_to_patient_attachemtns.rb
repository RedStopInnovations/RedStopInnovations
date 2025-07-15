class AddPatientCaseIdToPatientAttachemtns < ActiveRecord::Migration[5.0]
  def change
    add_column :patient_attachments, :patient_case_id, :integer

    add_index :patient_attachments, :patient_case_id
  end
end
