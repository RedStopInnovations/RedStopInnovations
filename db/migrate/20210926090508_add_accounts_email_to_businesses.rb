class AddAccountsEmailToBusinesses < ActiveRecord::Migration[5.2]
  def change
    add_column :businesses, :accounting_email, :string
  end
end
