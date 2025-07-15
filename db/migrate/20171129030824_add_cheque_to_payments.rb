class AddChequeToPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :payments, :cheque, :decimal, precision: 10, scale: 2, default: 0
  end
end
