class CreateUserGoogleCalendarSyncSettingTable < ActiveRecord::Migration[5.2]
  def change
    create_table :user_google_calendar_sync_settings do |t|
      t.integer :user_id, null: false, index: true
      t.string :calendar_id, null: false
      t.string :access_token
      t.string :refresh_token
      t.datetime :access_token_expires_at
      t.datetime :connected_at
      t.string :status
      t.timestamps null: false
    end
  end
end
