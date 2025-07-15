class CreateApiKeys < ActiveRecord::Migration[5.0]
  def change
    create_table :api_keys do |t|
      t.integer :user_id,     null: false
      t.string :token,        null: false
      t.boolean :active,      default: false
      t.datetime :created_at, null: false

      t.index :user_id
      t.index :token, unique: true
    end
  end
end
