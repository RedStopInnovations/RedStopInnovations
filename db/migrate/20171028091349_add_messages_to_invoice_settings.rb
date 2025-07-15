class AddMessagesToInvoiceSettings < ActiveRecord::Migration[5.0]
  def change
    add_column :invoice_settings, :messages, :text
  end
end
