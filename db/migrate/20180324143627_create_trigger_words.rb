class CreateTriggerWords < ActiveRecord::Migration[5.0]
  def change
    create_table :trigger_words do |t|
      t.integer :category_id, null: false
      t.string :text, null: false
      t.integer :mentions_count
      t.integer :patients_count
      t.timestamps

      t.index :category_id
    end
  end
end
