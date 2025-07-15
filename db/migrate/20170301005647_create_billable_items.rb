class CreateBillableItems < ActiveRecord::Migration[5.0]
  def change
    create_table :billable_items do |t|
      t.string :name
      t.string :description
      t.string :item_number
      t.integer :price

      t.timestamps
    end
  end
end
