# == Schema Information
#
# Table name: notification_types
#
#  id                         :string           not null, primary key
#  name                       :string           not null
#  description                :text
#  available_delivery_methods :jsonb
#  default_template           :jsonb
#  default_config             :jsonb
#
class NotificationType < ApplicationRecord
  self.table_name = 'notification_types'

  DELIVERY_METHOD__EMAIL = 'EMAIL'
  DELIVERY_METHOD__SMS   = 'SMS'

  APPOINTMENT__CREATED       = 'appointment.created'
  APPOINTMENT__BOOKED_ONLINE = 'appointment.booked_online'
  APPOINTMENT__UPDATED       = 'appointment.updated'
  APPOINTMENT__CANCELLED     = 'appointment.cancelled'
end
