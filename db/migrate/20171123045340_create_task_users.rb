class CreateTaskUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :task_users do |t|
      t.integer :user_id, null: :false
      t.integer :task_id, null: :false

      t.index :user_id
      t.index :task_id
    end
  end
end
