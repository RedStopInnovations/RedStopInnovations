class CreateXeroAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :xero_accounts do |t|
      t.integer :business_id, null: false
      t.string :organisation_name, null: false
      t.string :access_token, null: false
      t.string :access_key, null: false
      t.string :refresh_token
      t.datetime :access_token_expires_at
      t.string :default_sales_account_code
      t.string :default_payment_account_id
      t.string :default_exempt_tax_type

      t.timestamps

      t.index :business_id, unique: true
    end
  end
end
