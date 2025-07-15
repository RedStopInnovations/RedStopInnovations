class AddLastSendTimestampToInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :last_send_at, :datetime
  end
end
