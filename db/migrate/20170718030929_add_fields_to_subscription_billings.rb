class AddFieldsToSubscriptionBillings < ActiveRecord::Migration[5.0]
  def change
    add_column :subscription_billings, :business_invoice_id, :integer
    add_column :subscription_billings, :quantity, :integer
    remove_column :business_invoices, :stripe_payment_id, :string
  end
end
