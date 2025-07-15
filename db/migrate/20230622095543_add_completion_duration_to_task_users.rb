class AddCompletionDurationToTaskUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :task_users, :completion_duration, :integer
  end
end
