class AddDefaultExemptTaxIdToMyobAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :myob_accounts, :default_exempt_tax_id, :string
  end
end
