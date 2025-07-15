class AddBankDetailsToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :bank, :string
    add_column :practitioners, :name, :string
    add_column :practitioners, :bsb, :string
    add_column :practitioners, :account, :string
  end
end
