class CreateXeroPayments < ActiveRecord::Migration[5.0]
  def change
    create_table :xero_payments do |t|
      t.integer :payment_id, null: false   # Local payment id
      t.integer :invoice_id, null: false   # Local invoice id
      t.string :reference_payment_id, null: false # Payment ID from Xero
      t.string :reference_invoice_id, null: false # Invoice ID from Xero
      t.string :payment_type, null: false  # dva, medicare

      t.datetime :synced_at, null: false
      t.index :payment_id
      t.index :invoice_id

    end
  end
end
