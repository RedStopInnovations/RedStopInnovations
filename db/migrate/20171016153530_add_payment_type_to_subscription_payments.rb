class AddPaymentTypeToSubscriptionPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :subscription_payments, :payment_type, :string
  end
end
