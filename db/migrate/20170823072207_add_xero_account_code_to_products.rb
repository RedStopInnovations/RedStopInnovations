class AddXeroAccountCodeToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :xero_account_code, :string
  end
end
