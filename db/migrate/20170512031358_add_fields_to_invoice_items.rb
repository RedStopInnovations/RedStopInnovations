class AddFieldsToInvoiceItems < ActiveRecord::Migration[5.0]
  def change
    add_column :invoice_items, :unit_name, :string
    add_column :invoice_items, :tax_name, :string
    add_column :invoice_items, :tax_rate, :decimal, precision: 10, scale: 2
  end
end
