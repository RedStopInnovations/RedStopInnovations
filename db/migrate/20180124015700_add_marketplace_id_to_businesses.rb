class AddMarketplaceIdToBusinesses < ActiveRecord::Migration[5.0]
  def change
    add_column :businesses, :marketplace_id, :integer
    add_index :businesses, :marketplace_id
  end
end
