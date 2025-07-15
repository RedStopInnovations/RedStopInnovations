class CreateHicapsItems < ActiveRecord::Migration[5.0]
  def change
    create_table :hicaps_items do |t|
      t.string :item_number, null: false
      t.string :description, null: false
      t.string :abbr
      t.string :category

      t.index :item_number, unique: true
    end
  end
end
