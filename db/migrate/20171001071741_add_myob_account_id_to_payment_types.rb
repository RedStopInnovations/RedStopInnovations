class AddMyobAccountIdToPaymentTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :payment_types, :myob_account_id, :string
  end
end
