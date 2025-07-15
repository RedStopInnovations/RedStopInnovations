class AddFieldsToPatientCases < ActiveRecord::Migration[5.0]
  def change
    add_column :patient_cases, :invoice_total, :integer
    add_column :patient_cases, :invoice_number, :integer
  end
end
