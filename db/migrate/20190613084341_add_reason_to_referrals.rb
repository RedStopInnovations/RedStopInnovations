class AddReasonToReferrals < ActiveRecord::Migration[5.0]
  def change
    add_column :referrals, :referral_reason, :text
  end
end
