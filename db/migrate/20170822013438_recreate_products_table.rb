class RecreateProductsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.integer :business_id, null: false
      t.string :name, null: false
      t.string :item_code
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.decimal :cost_price, precision: 10, scale: 2, null: false, default: 0
      t.string :serial_number
      t.string :supplier_name
      t.string :supplier_phone
      t.string :supplier_email
      t.text :notes
      t.integer :stock_level
      t.integer :tax_id
      t.attachment :image

      t.index :business_id
    end
  end
end
