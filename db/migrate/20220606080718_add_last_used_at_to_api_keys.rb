class AddLastUsedAtToApiKeys < ActiveRecord::Migration[6.1]
  def change
    add_column :api_keys, :last_used_at, :datetime
    add_column :api_keys, :last_used_by_ip, :string
  end
end
