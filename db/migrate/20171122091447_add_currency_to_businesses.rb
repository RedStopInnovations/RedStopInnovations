class AddCurrencyToBusinesses < ActiveRecord::Migration[5.0]
  def change
    add_column :businesses, :currency, :string, default: 'aud'
  end
end
