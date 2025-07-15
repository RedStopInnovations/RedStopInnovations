class AddEmailToSubscriptions < ActiveRecord::Migration[6.1]
  def change
    add_column :subscriptions, :email, :string
  end
end
