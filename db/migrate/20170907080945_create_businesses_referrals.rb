class CreateBusinessesReferrals < ActiveRecord::Migration[5.0]
  def change
    create_table :businesses_referrals do |t|
      t.integer :referral_id, null: :false
      t.integer :business_id, null: :false

      t.index :referral_id
      t.index :business_id
    end
  end
end
