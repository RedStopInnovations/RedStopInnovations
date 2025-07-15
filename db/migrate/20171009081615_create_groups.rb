class CreateGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :groups do |t|
      t.string :name, null: :false
      t.text :description
      t.string :category
      t.integer :business_id, null: :false

      t.timestamps

      t.index :business_id
    end
  end
end
