class CreateReferralRejectReasons < ActiveRecord::Migration[7.0]
  def change
    create_table :referral_reject_reasons do |t|
      t.integer :business_id, null: false, index: true
      t.string :reason
      t.datetime :created_at
    end
  end
end
