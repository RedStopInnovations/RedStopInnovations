# == Schema Information
#
# Table name: notification_type_settings
#
#  id                       :bigint           not null, primary key
#  business_id              :integer          not null
#  notification_type_id     :string           not null
#  enabled_delivery_methods :jsonb
#  template                 :jsonb
#  enabled                  :boolean          default(TRUE)
#  config                   :jsonb
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_notification_type_settings_on_business_id           (business_id)
#  index_notification_type_settings_on_notification_type_id  (notification_type_id)
#
class NotificationTypeSetting < ApplicationRecord
  self.table_name = 'notification_type_settings'

  belongs_to :business
  belongs_to :notification_type

  def enabled_email_delivery?
    enabled_delivery_methods.include?(NotificationType::DELIVERY_METHOD__EMAIL)
  end

  def enabled_sms_delivery?
    enabled_delivery_methods.include?(NotificationType::DELIVERY_METHOD__SMS)
  end
end
