class AddBankDetailsToBusiness < ActiveRecord::Migration[5.0]
  def change
    change_table :businesses do |t|
      t.string :bank_name
      t.string :bank_branch_number # BSB
      t.string :bank_account_name
      t.string :bank_account_number
    end
  end
end
