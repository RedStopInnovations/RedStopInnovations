class AddTypeToReferrals < ActiveRecord::Migration[5.0]
  def change
    add_column :referrals, :type, :string
  end
end
