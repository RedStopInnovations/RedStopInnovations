class CreateInvoiceClaims < ActiveRecord::Migration[5.0]
  def change
    create_table :invoice_claims do |t|
      t.integer :invoice_id, null: false
      t.string :type, null: false
      t.string :status, null: false
      t.string :claiming_transaction_id, null: false
      t.index :invoice_id
      t.index :type
      t.timestamps
    end
  end
end
