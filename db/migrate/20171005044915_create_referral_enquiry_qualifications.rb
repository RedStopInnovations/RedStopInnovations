class CreateReferralEnquiryQualifications < ActiveRecord::Migration[5.0]
  def change
    create_table :referral_enquiry_qualifications do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :status
      t.string :token
      t.timestamp :expires_at

      t.integer :practitioner_id, null: :false

      t.timestamps

      t.index :practitioner_id
    end
  end
end
