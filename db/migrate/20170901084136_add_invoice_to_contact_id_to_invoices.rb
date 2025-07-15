class AddInvoiceToContactIdToInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :invoice_to_contact_id, :integer

    add_index :invoices, :invoice_to_contact_id
  end
end
