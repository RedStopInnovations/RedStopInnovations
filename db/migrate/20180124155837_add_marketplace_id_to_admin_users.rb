class AddMarketplaceIdToAdminUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :admin_users, :marketplace_id, :integer
    add_index :admin_users, :marketplace_id
  end
end
