class CreateBusinessStripeAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :business_stripe_accounts do |t|
      t.integer :business_id, null: false
      t.string :account_id, null: false
      t.string :access_token
      t.string :refresh_token
      t.string :publishable_key
      t.datetime :connected_at

      t.index :business_id, unique: true
    end
  end
end
