class AddCompleteDateToTaskUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :task_users, :complete_at, :datetime
  end
end
