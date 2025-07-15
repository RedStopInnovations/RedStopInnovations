class AddIsInvoiceRequiredToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :is_invoice_required, :boolean, default: true
  end
end
