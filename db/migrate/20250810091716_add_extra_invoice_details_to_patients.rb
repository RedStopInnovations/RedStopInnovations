class AddExtraInvoiceDetailsToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :extra_invoice_info, :text
  end
end
