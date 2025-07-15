class AddXeroIdToSyncableResources < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :xero_contact_id, :string
    add_column :invoices, :xero_invoice_id, :string
    add_column :invoice_items, :xero_line_item_id, :string
  end
end
