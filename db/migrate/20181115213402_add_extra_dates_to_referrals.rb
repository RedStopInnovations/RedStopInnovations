class AddExtraDatesToReferrals < ActiveRecord::Migration[5.0]
  def change
    add_column :referrals, :receieved_referral, :date
    add_column :referrals, :summary_referral, :string
  end
end
