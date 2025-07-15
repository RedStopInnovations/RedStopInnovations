class AddOutstandingReminderColumnsToInvoices < ActiveRecord::Migration[6.1]
  def change
    change_table :invoices do |t|
      t.json :outstanding_reminder, default: {}
    end
  end
end
