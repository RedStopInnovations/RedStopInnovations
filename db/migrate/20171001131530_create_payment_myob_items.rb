class CreatePaymentMyobItems < ActiveRecord::Migration[5.0]
  def change
    create_table :payment_myob_items do |t|
      t.integer :payment_id, null: false, index: true
      t.string :uid, null: false
      t.string :row_version, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0
      t.string :payment_type, null: false
      t.timestamps
    end
  end
end
