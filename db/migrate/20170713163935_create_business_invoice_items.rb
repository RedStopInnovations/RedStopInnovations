class CreateBusinessInvoiceItems < ActiveRecord::Migration[5.0]
  def change
    create_table :business_invoice_items do |t|
      t.references :business_invoice
      t.string :unit_name
      t.decimal :unit_price, precision: 10, scale: 2, default: 0
      t.integer :quantity
      t.decimal :discount, precision: 10, scale: 2, default: 0
      t.decimal :amount, precision: 10, scale: 2, default: 0
      t.decimal :tax, precision: 10, scale: 2, default: 0
      t.timestamps
    end
  end
end
