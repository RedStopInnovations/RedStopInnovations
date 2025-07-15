class AddDirectDepositToPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :payments, :direct_deposit, :decimal, precision: 10, scale: 2, default: 0
  end
end
