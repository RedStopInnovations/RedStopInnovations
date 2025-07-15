class AddPaymentDetailsToPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :payments, :payment_method, :string
    add_column :payments, :payment_method_status, :boolean
    add_column :payments, :payment_method_status_info, :text
  end
end
