class AddUpdatedAtToTaskUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :task_users, :updated_at, :datetime
  end
end
