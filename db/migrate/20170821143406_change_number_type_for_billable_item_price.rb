class ChangeNumberTypeForBillableItemPrice < ActiveRecord::Migration[5.0]
  def change
    change_column :billable_items, :price, :decimal, precision: 10, scale: 2, null: false, default: 0
  end
end
