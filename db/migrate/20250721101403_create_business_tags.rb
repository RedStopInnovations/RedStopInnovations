class CreateBusinessTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.integer :business_id, null: false, index: true
      t.string :tag_type, null: false
      t.string :name, null: false
      t.string :color, null: false, default: '#000000'
      t.timestamps
    end
  end
end
