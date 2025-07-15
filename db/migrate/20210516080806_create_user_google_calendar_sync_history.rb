class CreateUserGoogleCalendarSyncHistory < ActiveRecord::Migration[5.2]
  def change
    create_table :user_google_calendar_sync_history do |t|
      t.integer :user_id, null: false
      t.string :event_id, null: false
      t.integer :appointment_id, null: false
      t.datetime :created_at, null: false
    end
  end
end
