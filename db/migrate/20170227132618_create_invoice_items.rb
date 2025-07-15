class CreateInvoiceItems < ActiveRecord::Migration[5.0]
  def change
    create_table :invoice_items do |t|
      t.integer :invoice_id, null: false
      t.integer :product_id, null: false
      t.integer :quantity, null: false
      t.float :unit_price, null: false

      t.timestamps
    end
    add_index :invoice_items, :invoice_id
    add_index :invoice_items, :product_id
  end
end
