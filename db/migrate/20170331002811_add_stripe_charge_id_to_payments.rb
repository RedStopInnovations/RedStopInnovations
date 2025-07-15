class AddStripeChargeIdToPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :payments, :stripe_charge_id, :string
  end
end
