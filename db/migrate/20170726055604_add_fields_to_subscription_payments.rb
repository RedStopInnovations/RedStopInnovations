class AddFieldsToSubscriptionPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :subscription_payments, :business_id, :integer
  end
end
