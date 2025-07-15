class CreateTags < ActiveRecord::Migration[5.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.index :slug, unique: true
    end
  end
end
