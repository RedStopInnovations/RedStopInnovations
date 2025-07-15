class CreatePosts < ActiveRecord::Migration[5.0]
  def change
    create_table :posts do |t|
      t.integer :practitioner_id, null: false
      t.string :title, null: false
      t.string :slug, null: false
      t.text :meta_description
      t.text :meta_keywords
      t.text :summary
      t.text :content
      t.boolean :published, null: false, default: false
      t.attachment :thumbnail
      t.timestamps

      t.index :slug, unique: true
      t.index :practitioner_id
      t.index :published
      t.index [:practitioner_id, :published]
    end
  end
end
