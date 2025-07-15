class AddDeletedAtToSubscriptionInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :business_invoices, :deleted_at, :datetime
  end
end
