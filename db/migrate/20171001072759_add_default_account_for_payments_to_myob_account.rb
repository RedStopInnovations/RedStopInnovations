class AddDefaultAccountForPaymentsToMyobAccount < ActiveRecord::Migration[5.0]
  def change
    add_column :myob_accounts, :default_payment_account_id, :string
  end
end
