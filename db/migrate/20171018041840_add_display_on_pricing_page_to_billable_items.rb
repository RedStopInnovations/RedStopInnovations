class AddDisplayOnPricingPageToBillableItems < ActiveRecord::Migration[5.0]
  def change
    add_column :billable_items, :display_on_pricing_page, :boolean, default: :true
  end
end
