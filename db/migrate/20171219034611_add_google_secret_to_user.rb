class AddGoogleSecretToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :google_authenticator_secret, :string
    add_column :users, :enable_google_authenticator, :boolean, default: :false
  end
end
