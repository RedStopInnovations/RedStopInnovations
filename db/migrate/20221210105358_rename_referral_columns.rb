class RenameReferralColumns < ActiveRecord::Migration[6.1]
  def change
    rename_column :referrals, :business_name, :referrer_business_name
    rename_column :referrals, :name, :referrer_name
    rename_column :referrals, :phone, :referrer_phone
    rename_column :referrals, :email, :referrer_email

    rename_column :referrals, :receieved_referral, :receive_referral_date
    rename_column :referrals, :notes, :medical_note
  end
end
