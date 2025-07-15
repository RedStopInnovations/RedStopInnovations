class ModifyTasksAndTaskUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :tasks, :user_id
    add_column :task_users, :status, :string
  end
end
