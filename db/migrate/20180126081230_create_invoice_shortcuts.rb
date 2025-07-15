class CreateInvoiceShortcuts < ActiveRecord::Migration[5.0]
  def change
    create_table :invoice_shortcuts do |t|
      t.text :content
      t.integer :business_id, index: true
      t.string :category
    end
  end
end
