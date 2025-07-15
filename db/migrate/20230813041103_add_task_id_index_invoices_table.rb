class AddTaskIdIndexInvoicesTable < ActiveRecord::Migration[7.0]
  def change
    add_index :invoices, :task_id
  end
end
