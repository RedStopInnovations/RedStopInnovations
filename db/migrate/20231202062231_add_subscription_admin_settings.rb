class AddSubscriptionAdminSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :subscriptions, :admin_settings, :jsonb, default: {}
  end
end
