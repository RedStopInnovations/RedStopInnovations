class ChangeAmountAndUnitPriceInvoiceItems < ActiveRecord::Migration[5.0]
  def change
    change_table :invoice_items do |t|
      t.decimal :amount, precision: 10, scale: 2, default: 0
      t.change :unit_price, :decimal, precision: 10, scale: 2, default: 0
    end
  end
end
