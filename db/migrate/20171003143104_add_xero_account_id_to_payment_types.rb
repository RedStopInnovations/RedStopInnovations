class AddXeroAccountIdToPaymentTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :payment_types, :xero_account_id, :string
  end
end
