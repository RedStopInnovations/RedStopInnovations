class AddSocialMediaLinksAndMoreToPractitioners < ActiveRecord::Migration[5.0]
  def change
    change_table :practitioners do |t|
      t.string :abn
      t.string :facebook_url
      t.string :twitter_url
      t.string :linkedin_url
      t.string :youtube_url
      t.string :video_url

      t.string :clinic_name
      t.string :clinic_website
      t.string :clinic_phone
      t.string :clinic_booking_url
    end
  end
end
