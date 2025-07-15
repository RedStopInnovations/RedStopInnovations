class RemoveBankDetailsFromPractitioners < ActiveRecord::Migration[5.0]
  def change
    remove_column :practitioners, :bank, :string
    remove_column :practitioners, :name, :string
    remove_column :practitioners, :bsb, :string
    remove_column :practitioners, :account, :string
  end
end
