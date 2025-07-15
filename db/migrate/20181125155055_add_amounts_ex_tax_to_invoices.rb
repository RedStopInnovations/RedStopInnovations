class AddAmountsExTaxToInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :amount_ex_tax, :decimal, precision: 10, scale: 2, default: 0, null: false
  end
end
