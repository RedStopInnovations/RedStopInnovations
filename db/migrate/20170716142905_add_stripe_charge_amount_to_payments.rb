class AddStripeChargeAmountToPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :payments,
               :stripe_charge_amount,
               :decimal,
               precision: 10,
               scale: 2,
               default: 0,
               after: :stripe_charge_id
  end
end
