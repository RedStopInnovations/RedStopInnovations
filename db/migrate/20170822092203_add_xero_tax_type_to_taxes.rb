class AddXeroTaxTypeToTaxes < ActiveRecord::Migration[5.0]
  def change
    add_column :taxes, :xero_tax_type, :string
  end
end
