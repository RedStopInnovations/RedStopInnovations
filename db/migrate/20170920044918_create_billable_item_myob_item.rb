class CreateBillableItemMyobItem < ActiveRecord::Migration[5.0]
  def change
    create_table :billable_item_myob_items do |t|
      t.integer :billable_item_id, null: :false
      t.string :uid
      t.string :account_id
      t.string :tax_id
      t.string :row_version

      t.timestamps

      t.index :billable_item_id
    end
  end
end