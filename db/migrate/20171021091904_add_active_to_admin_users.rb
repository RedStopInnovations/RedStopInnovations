class AddActiveToAdminUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :admin_users, :active, :boolean, default: :true
  end
end
