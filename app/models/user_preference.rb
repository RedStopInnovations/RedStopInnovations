# == Schema Information
#
# Table name: user_preferences
#
#  id         :bigint           not null, primary key
#  user_id    :integer          not null
#  key        :string           not null
#  value_type :string           default("string"), not null
#  value      :text
#
# Indexes
#
#  index_user_preferences_on_user_id          (user_id)
#  index_user_preferences_on_user_id_and_key  (user_id,key) UNIQUE
#
class UserPreference < ApplicationRecord
  belongs_to :user

  KEYS = [
    DASHBOARD_OVERVIEW_REPORT_DATE_RANGE = 'dashboard_overview_report_date_range',
    DASHBOARD_OVERVIEW_REPORT_SCOPE = 'dashboard_overview_report_scope',
    ALERT_USERS_NOT_ENABLED_2FA_DISMISSED_AT = 'alert.users_not_enabled_2fa_dismissed_at',
    ALERT_RECOMMEND_DATA_BACKUP_DISMISSED_AT = 'alert.recommend_data_backup_dismissed_at',
  ]

  # @TODO: update type casting
  # @see: https://api.rubyonrails.org/classes/ActiveModel/Type.html
  VALUE_TYPES = [
    'string',
    'boolean',
    'array',
    'hash',
  ]

  validates :key,
            presence: true,
            inclusion: { in: KEYS }

  validates :value,
            length: { maximum: 256 },
            allow_nil: true,
            allow_blank: true
end
