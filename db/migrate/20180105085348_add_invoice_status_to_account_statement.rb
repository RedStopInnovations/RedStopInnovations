class AddInvoiceStatusToAccountStatement < ActiveRecord::Migration[5.0]
  def change
    add_column :patient_statements, :invoice_status, :string
    add_column :contact_statements, :invoice_status, :string
  end
end
