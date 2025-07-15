class AddActiveToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :active, :boolean, default: true
    add_index :users, :active
    add_index :users, [:business_id, :active]
  end
end
