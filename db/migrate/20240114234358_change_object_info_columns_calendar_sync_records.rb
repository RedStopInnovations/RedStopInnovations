class ChangeObjectInfoColumnsCalendarSyncRecords < ActiveRecord::Migration[7.1]
  def change
    rename_column :user_google_calendar_sync_records, :object_id, :sync_object_id
    rename_column :user_google_calendar_sync_records, :object_type, :sync_object_type
  end
end
