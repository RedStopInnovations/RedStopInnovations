class AddPublicTokenToInvoices < ActiveRecord::Migration[6.1]
  def change
    add_column :invoices, :public_token, :string, unique: true
  end
end
