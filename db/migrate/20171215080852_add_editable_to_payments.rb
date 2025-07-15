class AddEditableToPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :payments, :editable, :boolean, default: true
  end
end
