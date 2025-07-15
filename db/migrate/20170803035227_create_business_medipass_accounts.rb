class CreateBusinessMedipassAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :business_medipass_accounts do |t|
      t.integer :business_id, null: false
      t.string :api_key, null: false

      t.index :business_id, unique: true
      t.timestamps
    end
  end
end
