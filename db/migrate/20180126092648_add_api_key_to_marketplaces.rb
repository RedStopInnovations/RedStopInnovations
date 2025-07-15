class AddApiKeyToMarketplaces < ActiveRecord::Migration[5.0]
  def change
    add_column :marketplaces, :api_key, :string
  end
end
