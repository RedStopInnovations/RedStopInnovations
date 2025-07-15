# == Schema Information
#
# Table name: user_google_calendar_sync_history
#
#  id             :bigint           not null, primary key
#  user_id        :integer          not null
#  event_id       :string           not null
#  appointment_id :integer          not null
#  created_at     :datetime         not null
#

# TODO: remove after #2309 is deployed
class UserGoogleCalendarSyncHistory < ApplicationRecord
  self.table_name = 'user_google_calendar_sync_history'
end
