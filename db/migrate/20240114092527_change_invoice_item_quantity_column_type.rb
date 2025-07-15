class ChangeInvoiceItemQuantityColumnType < ActiveRecord::Migration[7.1]
  def change
    change_column :invoice_items, :quantity, :decimal, precision: 10, scale: 2
  end
end
