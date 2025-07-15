class CreateSubscriptionPayments < ActiveRecord::Migration[5.0]
  def change
    create_table :subscription_payments do |t|
      t.references :business_invoice
      t.datetime :payment_date
      t.decimal :amount, precision: 10, scale: 2, default: 0
      t.string :stripe_charge_id
      t.timestamps
    end
  end
end
