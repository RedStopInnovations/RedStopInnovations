class CreateInvoicesPdfExports < ActiveRecord::Migration[5.2]
  def change
    create_table :invoices_pdf_exports do |t|
      t.integer :business_id, null: false, index: true
      t.integer :author_id, null: false, index: true
      t.json :options
      t.text :description
      t.string :status, null: false
      t.timestamps
    end
  end
end
