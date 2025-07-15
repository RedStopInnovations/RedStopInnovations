class CreateDeletedResources < ActiveRecord::Migration[5.0]
  def change
    create_table :deleted_resources do |t|
      t.integer :business_id, null: false
      t.integer :resource_id, null: false
      t.string :resource_type, null: false
      t.integer :author_id
      t.string :author_type

      t.datetime :deleted_at, null: false
      t.index :business_id
    end
  end
end
