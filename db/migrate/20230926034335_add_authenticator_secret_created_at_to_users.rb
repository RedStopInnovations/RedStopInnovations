class AddAuthenticatorSecretCreatedAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :google_authenticator_secret_created_at, :datetime
  end
end
