class AddLastSendContactAtToInvoices < ActiveRecord::Migration[6.1]
  def change
    add_column :invoices, :last_send_contact_at, :datetime
  end
end
