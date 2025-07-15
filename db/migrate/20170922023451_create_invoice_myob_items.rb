class CreateInvoiceMyobItems < ActiveRecord::Migration[5.0]
  def change
    create_table :invoice_myob_items do |t|
      t.integer :invoice_id, null: :false
      t.string :uid
      t.string :row_version

      t.timestamps

      t.index :invoice_id
    end
  end
end
