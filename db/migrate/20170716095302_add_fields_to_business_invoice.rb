class AddFieldsToBusinessInvoice < ActiveRecord::Migration[5.0]
  def change
    add_column :business_invoices, :notes, :text
  end
end
