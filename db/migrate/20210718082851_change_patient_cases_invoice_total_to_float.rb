class ChangePatientCasesInvoiceTotalToFloat < ActiveRecord::Migration[5.2]
  def change
    change_column :patient_cases, :invoice_total, :float
  end
end
