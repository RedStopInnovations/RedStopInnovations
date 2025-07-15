class CreatePaymentLocations < ActiveRecord::Migration[5.0]
  def change
    create_table :payment_allocations do |t|
      t.integer :payment_id, null: false
      t.integer :invoice_id, null: false
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.timestamps

      t.index :payment_id
      t.index :invoice_id
    end
  end
end
