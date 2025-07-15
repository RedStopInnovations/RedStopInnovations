class AddMessageToInvoices < ActiveRecord::Migration[7.0]
  def change
    add_column :invoices, :message, :text
  end
end
