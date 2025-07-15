class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :item_code
      t.string :serial_number
      t.integer :stock_level
      t.integer :price
      t.integer :cost_price
      t.string :supplier_name
      t.string :supplier_phone
      t.string :supplier_email
      t.string :supplier_website
      t.text :notes

      t.timestamps
    end
  end
end
