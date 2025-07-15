class AddPostsTagsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :posts_tags do |t|
      t.integer :post_id, null: false
      t.integer :tag_id, null: false

      t.timestamps null: false
    end

    add_index :posts_tags, :post_id
    add_index :posts_tags, :tag_id
  end
end
