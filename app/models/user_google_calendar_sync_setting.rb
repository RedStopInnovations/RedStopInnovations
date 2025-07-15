# == Schema Information
#
# Table name: user_google_calendar_sync_settings
#
#  id                      :bigint           not null, primary key
#  user_id                 :integer          not null
#  calendar_id             :string           not null
#  access_token            :string
#  refresh_token           :string
#  access_token_expires_at :datetime
#  connected_at            :datetime
#  status                  :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_user_google_calendar_sync_settings_on_user_id  (user_id)
#
class UserGoogleCalendarSyncSetting < ApplicationRecord
  STATUS_ACTIVE = 'active'
  STATUS_ERROR = 'error'

  belongs_to :user, class_name: 'User'

  scope :status_active, -> { where(status: STATUS_ACTIVE) }

  def status_active?
    status == STATUS_ACTIVE
  end
end
