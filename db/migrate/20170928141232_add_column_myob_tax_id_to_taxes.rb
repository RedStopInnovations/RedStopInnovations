class AddColumnMyobTaxIdToTaxes < ActiveRecord::Migration[5.0]
  def change
    add_column :taxes, :myob_tax_id, :string
  end
end
