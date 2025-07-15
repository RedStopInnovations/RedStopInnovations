class DeviseCreateAdminUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :admin_users do |t|
      t.string :first_name
      t.string :last_name
      t.string :full_name

      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      t.timestamps null: false
    end

    add_index :admin_users, :email,                unique: true
    add_index :admin_users, :reset_password_token, unique: true
  end
end
