class ChangeIndexesFromHicapsTable < ActiveRecord::Migration[5.0]
  def change
    # Remove unique constrain for item_number index
    remove_index :hicaps_items, :item_number
    add_index :hicaps_items, :item_number
  end
end
