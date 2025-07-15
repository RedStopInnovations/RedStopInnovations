class CreateMyobAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :myob_accounts do |t|
      t.integer :business_id, null: false
      t.string :access_token
      t.string :refresh_token
      t.datetime :access_token_expires_at
      t.string :company_file_id
      t.string :default_tax_id
      t.string :default_freight_id
      t.string :default_invoice_item_tax_id
      t.string :default_invoice_item_account_id

      t.timestamps

      t.index :business_id
    end
  end
end
