class CreateProductMyobItems < ActiveRecord::Migration[5.0]
  def change
    create_table :product_myob_items do |t|
      t.integer :product_id, null: :false
      t.string :uid
      t.string :account_id
      t.string :tax_id
      t.string :row_version

      t.timestamps

      t.index :product_id
    end
  end
end