class AddInvoiceNumberToInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :invoice_number, :string, null: false, default: ''
    add_index :invoices, :invoice_number
    add_index :invoices, [:business_id, :invoice_number]
  end
end
