class AddSubscriptionInvoiceIdToSubscriptionPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :subscription_payments, :invoice_id, :integer
    add_index :subscription_payments, :invoice_id
  end
end
