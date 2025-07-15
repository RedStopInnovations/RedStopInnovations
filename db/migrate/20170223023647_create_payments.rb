class CreatePayments < ActiveRecord::Migration[5.0]
  def change
    create_table :payments do |t|
      t.date :payment_date
      t.integer :eftpos
      t.integer :hicaps
      t.integer :cash
      t.integer :medicare
      t.integer :workcover
      t.integer :dva
      t.integer :other
      t.integer :amount
      t.references :invoice, null: false
      t.timestamps
    end
  end
end
