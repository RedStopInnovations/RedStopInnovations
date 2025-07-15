class AddPatientCaseIdToInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :patient_case_id, :integer
    add_index :invoices, :patient_case_id
  end
end
