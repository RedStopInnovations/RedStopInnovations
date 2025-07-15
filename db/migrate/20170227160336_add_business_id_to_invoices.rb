class AddBusinessIdToInvoices < ActiveRecord::Migration[5.0]
  def change
    change_table :invoices do |t|
      t.references :business, index: true
    end
  end
end
