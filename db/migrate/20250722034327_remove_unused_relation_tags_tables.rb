class RemoveUnusedRelationTagsTables < ActiveRecord::Migration[7.1]
  def change
    drop_table :practitioners_tags, if_exists: true
    drop_table :posts_tags, if_exists: true
  end
end
