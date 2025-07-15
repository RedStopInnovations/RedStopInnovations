class AddPriorityToReferrals < ActiveRecord::Migration[5.0]
  def change
    add_column :referrals, :priority, :string
  end
end
