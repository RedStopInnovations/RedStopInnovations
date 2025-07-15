class AddAcceptAndRejectTimestampsToReferrals < ActiveRecord::Migration[7.0]
  def change
    add_column :referrals, :approved_at, :datetime
    add_column :referrals, :rejected_at, :datetime
  end
end
