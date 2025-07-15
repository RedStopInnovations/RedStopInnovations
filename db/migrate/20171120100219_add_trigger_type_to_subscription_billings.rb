class AddTriggerTypeToSubscriptionBillings < ActiveRecord::Migration[5.0]
  def change
    add_column :subscription_billings, :trigger_type, :string
  end
end
