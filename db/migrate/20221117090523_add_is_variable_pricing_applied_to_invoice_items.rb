class AddIsVariablePricingAppliedToInvoiceItems < ActiveRecord::Migration[6.1]
  def change
    add_column :invoice_items, :is_variable_pricing_applied, :boolean, default: false
  end
end
