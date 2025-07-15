class CreateHicapsTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :hicaps_transactions do |t|
      t.integer :payment_id, null: false # Internal payment id
      t.string :transaction_id, null: false # HICAPS transaction id
      t.datetime :requested_at
      t.datetime :approved_at
      t.string :status
      t.float :amount_benefit # hicaps
      t.float :amount_gap # eftpos
      t.datetime :created_at

      t.index :payment_id
    end
  end
end
