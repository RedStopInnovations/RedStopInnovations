class AddDescriptionToSubscriptionBillings < ActiveRecord::Migration[6.1]
  def change
    add_column :subscription_billings, :description, :text
  end
end
