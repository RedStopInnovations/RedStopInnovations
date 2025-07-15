class AddRejectReasonToReferrals < ActiveRecord::Migration[6.1]
  def change
    add_column :referrals, :reject_reason, :string, default: nil
  end
end
