class AddProviderNumberToInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :provider_number, :string
  end
end
