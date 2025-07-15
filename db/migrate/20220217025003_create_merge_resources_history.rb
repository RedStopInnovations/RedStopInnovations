class CreateMergeResourcesHistory < ActiveRecord::Migration[6.1]
  def change
    create_table :merge_resources_history do |t|
      t.integer :author_id, index: true, null: false
      t.string :resource_type, index: true, null: false
      t.integer :target_resource_id, index: true, null: false
      t.string :merged_resource_ids, null: false
      t.text :meta, null: true

      t.timestamps
    end
  end
end
