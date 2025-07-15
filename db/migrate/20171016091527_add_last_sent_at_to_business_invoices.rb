class AddLastSentAtToBusinessInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :business_invoices, :last_sent_at, :datetime
  end
end
