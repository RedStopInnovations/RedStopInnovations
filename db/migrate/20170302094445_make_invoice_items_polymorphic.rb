class MakeInvoiceItemsPolymorphic < ActiveRecord::Migration[5.0]
  def change
    change_table :invoice_items do |t|
      t.remove :product_id
      t.string :invoiceable_type
      t.integer :invoiceable_id

      t.index [:invoiceable_id, :invoiceable_type]
    end
  end
end
