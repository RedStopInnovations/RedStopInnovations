class AddLastSendAtToInvoiceBatches < ActiveRecord::Migration[7.1]
  def change
    add_column :invoice_batches, :last_send_at, :datetime, null: true
  end
end
