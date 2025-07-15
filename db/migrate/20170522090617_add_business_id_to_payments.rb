class AddBusinessIdToPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :payments, :business_id, :integer, index: true
  end
end
