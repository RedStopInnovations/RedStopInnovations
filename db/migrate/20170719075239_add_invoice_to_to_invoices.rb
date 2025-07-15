class AddInvoiceToToInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :invoice_to, :text
  end
end
