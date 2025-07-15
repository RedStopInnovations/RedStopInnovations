class CreateImages < ActiveRecord::Migration[5.0]
  def change
    create_table :images do |t|
      t.string :file
      t.integer :user_id

      t.timestamps
    end
    add_index :images, :user_id
  end
end
