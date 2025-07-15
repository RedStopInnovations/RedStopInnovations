class CreateTriggerCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :trigger_categories do |t|
      t.integer :business_id, null: false
      t.string :name
      t.integer :words_count, null: false, default: 0
      t.timestamps

      t.index :business_id
    end
  end
end
