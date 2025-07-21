class RemoveTagsSeopagesCouresPostsAndOldIntegrationsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :tags, if_exists: true
    drop_table :seopages, if_exists: true
    drop_table :marketplaces, if_exists: true
    drop_table :courses, if_exists: true
    drop_table :posts, if_exists: true
    drop_table :cpd_certificates, if_exists: true
    drop_table :subscription_discounts, if_exists: true

    remove_column :businesses, :marketplace_id, if_exists: true
    remove_column :admin_users, :marketplace_id, if_exists: true
  end
end
