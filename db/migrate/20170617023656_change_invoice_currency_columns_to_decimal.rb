class ChangeInvoiceCurrencyColumnsToDecimal < ActiveRecord::Migration[5.0]
  def self.up
    change_table :invoices do |t|
      t.change :amount, :decimal, precision: 10, scale: 2, default: 0
      t.change :outstanding, :decimal, precision: 10, scale: 2, default: 0
      t.change :subtotal, :decimal, precision: 10, scale: 2, default: 0
      t.change :discount, :decimal, precision: 10, scale: 2, default: 0
      t.change :tax, :decimal, precision: 10, scale: 2, default: 0
    end
  end

  def self.down
    change_table :invoices do |t|
      t.change :amount, :integer
      t.change :outstanding, :integer
      t.change :subtotal, :integer
      t.change :discount, :integer
      t.change :tax, :integer
    end
  end
end
