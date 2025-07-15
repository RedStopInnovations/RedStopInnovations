class CreateBillableItemsPractitionersJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table :billable_items_practitioners do |t|
      t.integer :billable_item_id, null: false, index: true
      t.integer :practitioner_id, null: false, index: true
    end
  end
end
