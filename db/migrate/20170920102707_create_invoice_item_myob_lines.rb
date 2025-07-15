class CreateInvoiceItemMyobLines < ActiveRecord::Migration[5.0]
  def change
    create_table :invoice_item_myob_lines do |t|
      t.integer :invoice_item_id, null: :false
      t.integer :row_id
      t.string :row_version

      t.timestamps

      t.index :row_id
      t.index :invoice_item_id
    end
  end
end
