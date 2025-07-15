class AddTriggersToSubscriptionBillings < ActiveRecord::Migration[5.0]
  def change
    add_column :subscription_billings, :triggers, :text
  end
end
