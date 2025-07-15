class RemoveIsVariablePricingAppliedFlagFromInvoiceItems < ActiveRecord::Migration[7.0]
  def change
    remove_column :invoice_items, :is_variable_pricing_applied
  end
end
