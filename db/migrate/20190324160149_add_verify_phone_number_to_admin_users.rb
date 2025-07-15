class AddVerifyPhoneNumberToAdminUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :admin_users, :enabled_2fa, :boolean, default: false
    add_column :admin_users, :mobile, :string
    add_column :admin_users, :encrypted_verify_code, :string
    add_column :admin_users, :verify_code_expires_at, :datetime
  end
end
