class CreateSubscriptionBillings < ActiveRecord::Migration[5.0]
  def change
    create_table :subscription_billings do |t|
      t.references :subscription
      t.references :appointment
      t.datetime :first_invoice_date
      t.string :billing_type
      t.decimal :subscription_price_on_date, precision: 10, scale: 2, default: 0
      t.decimal :discount_applied, precision: 10, scale: 2, default: 0
      t.timestamps
    end
  end
end
