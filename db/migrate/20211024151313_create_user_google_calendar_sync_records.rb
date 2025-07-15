class CreateUserGoogleCalendarSyncRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :user_google_calendar_sync_records do |t|
      t.integer :user_id, null: false, index: true

      t.string :calendar_event_id, null: false, index: true
      t.string :calendar_id, null: false

      t.integer :object_id, null: false
      t.string :object_type, null: false

      t.datetime :last_sync_at
      t.json :last_sync_state
      t.datetime :created_at, null: false

      t.index [:object_id, :object_type], name: :idx_google_calendar_sync_object_id_object_type
    end
  end
end
