class ChangeDueAtToDueOnForTasks < ActiveRecord::Migration[5.0]
  def change
    rename_column :tasks, :due_at, :due_on
  end
end
