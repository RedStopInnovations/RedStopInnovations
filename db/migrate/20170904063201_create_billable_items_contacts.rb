class CreateBillableItemsContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :billable_items_contacts do |t|
      t.integer :billable_item_id, null: :false
      t.integer :contact_id, null: :false

      t.decimal :price, precision: 10, scale: 2, null: false, default: 0

      t.timestamps

      t.index :billable_item_id
      t.index :contact_id
    end
  end
end
