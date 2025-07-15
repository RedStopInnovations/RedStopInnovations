class CreateTasks < ActiveRecord::Migration[5.0]
  def change
    create_table :tasks do |t|
      t.string :name
      t.string :priority
      t.text :description
      t.date :due_at
      t.string :status
      t.integer :user_id
      t.integer :business_id, null: :false
      t.integer :owner_id, null: :false
      t.timestamps

      t.index :user_id
      t.index :business_id
      t.index :owner_id
    end
  end
end
