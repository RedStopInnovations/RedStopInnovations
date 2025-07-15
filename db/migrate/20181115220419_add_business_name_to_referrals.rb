class AddBusinessNameToReferrals < ActiveRecord::Migration[5.0]
  def change
    add_column :referrals, :business_name, :string
  end
end
