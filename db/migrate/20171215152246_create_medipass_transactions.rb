class CreateMedipassTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :medipass_transactions do |t|
      t.integer  :invoice_id, null: false     # Internal invoice id
      t.integer  :payment_id
      t.string   :transaction_id, null: false # Medipass transaction id
      t.datetime :requested_at
      t.datetime :approved_at
      t.datetime :cancelled_at
      t.string   :status, null: false
      t.decimal  :amount_benefit, precision: 10, scale: 2, default: 0 # hicaps
      t.decimal  :amount_gap, precision: 10, scale: 2, default: 0 # eftpos
      t.string   :token, null: false # Verify token for webhook


      t.index :invoice_id
      t.index :payment_id
      t.datetime :created_at
    end
  end
end
