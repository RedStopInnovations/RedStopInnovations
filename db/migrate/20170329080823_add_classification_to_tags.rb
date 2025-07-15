class AddClassificationToTags < ActiveRecord::Migration[5.0]
  def change
    add_column :tags, :classification, :string
    add_index :tags, :classification
  end
end
