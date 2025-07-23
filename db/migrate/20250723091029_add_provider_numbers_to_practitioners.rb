class AddProviderNumbersToPractitioners < ActiveRecord::Migration[7.1]
  def change
    add_column :practitioners, :provider_numbers, :jsonb, default: []
  end
end
