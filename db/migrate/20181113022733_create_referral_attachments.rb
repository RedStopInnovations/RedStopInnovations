class CreateReferralAttachments < ActiveRecord::Migration[5.0]
  def change
    create_table :referral_attachments do |t|
      t.integer :referral_id, index: true
      t.attachment :attachment
      t.timestamps
    end
  end
end
