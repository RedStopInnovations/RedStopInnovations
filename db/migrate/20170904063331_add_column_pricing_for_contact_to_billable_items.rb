class AddColumnPricingForContactToBillableItems < ActiveRecord::Migration[5.0]
  def change
    add_column :billable_items, :pricing_for_contact, :boolean, default: :false
  end
end
