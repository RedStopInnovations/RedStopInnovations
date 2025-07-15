class AddCompanyFileNameToMyobAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :myob_accounts, :company_file_name, :string, after: :company_file_id
  end
end
