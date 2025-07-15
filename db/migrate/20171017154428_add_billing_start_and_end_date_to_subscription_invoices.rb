class AddBillingStartAndEndDateToSubscriptionInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :business_invoices, :billing_start_date, :datetime
    add_column :business_invoices, :billing_end_date, :datetime
  end
end
