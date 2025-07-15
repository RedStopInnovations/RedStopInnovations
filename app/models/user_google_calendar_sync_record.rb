# == Schema Information
#
# Table name: user_google_calendar_sync_records
#
#  id                :bigint           not null, primary key
#  user_id           :integer          not null
#  calendar_event_id :string           not null
#  calendar_id       :string           not null
#  sync_object_id    :integer          not null
#  sync_object_type  :string           not null
#  last_sync_at      :datetime
#  last_sync_state   :json
#  created_at        :datetime         not null
#
# Indexes
#
#  idx_google_calendar_sync_object_id_object_type                (sync_object_id,sync_object_type)
#  index_user_google_calendar_sync_records_on_calendar_event_id  (calendar_event_id)
#  index_user_google_calendar_sync_records_on_user_id            (user_id)
#
class UserGoogleCalendarSyncRecord < ApplicationRecord
  self.table_name = 'user_google_calendar_sync_records'

  belongs_to :sync_object, polymorphic: true
  belongs_to :user
end
