class ChangeFieldsFromSubscriptionPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :business_invoices, :subscription_payment_id, :integer
    remove_column :subscription_payments, :business_invoice_id
  end
end
