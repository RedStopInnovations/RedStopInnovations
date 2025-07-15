class RemoveTaxAndDiscountFromSubscriptionInvoiceItems < ActiveRecord::Migration[5.0]
  def change
    remove_column :business_invoice_items, :tax
    remove_column :business_invoice_items, :discount
  end
end
