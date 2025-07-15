class AddTaskIdAndServiceDateToInvoices < ActiveRecord::Migration[7.0]
  def change
    add_column :invoices, :service_date, :date
    add_column :invoices, :task_id, :integer
  end
end
