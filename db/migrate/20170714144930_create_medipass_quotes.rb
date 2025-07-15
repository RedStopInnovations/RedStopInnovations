class CreateMedipassQuotes < ActiveRecord::Migration[5.0]
  def change
    create_table :medipass_quotes do |t|
      t.integer :invoice_id, null: false
      t.string :transaction_id, null: false
      t.string :member_id, null: false
      t.decimal :amount_gap, precision: 10, scale: 2, default: 0
      t.decimal :amount_benefit, precision: 10, scale: 2, default: 0
      t.decimal :amount_fee, precision: 10, scale: 2, default: 0
      t.decimal :amount_charged, precision: 10, scale: 2, default: 0
      t.decimal :amount_discount, precision: 10, scale: 2, default: 0
      t.timestamps

      t.index :invoice_id
    end
  end
end
