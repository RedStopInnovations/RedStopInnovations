class AddOutstandingInvoiceReminderToInvoiceSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :invoice_settings, :outstanding_reminder, :json, default: {}
  end
end
