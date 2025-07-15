# == Schema Information
#
# Table name: daily_appointments_notifications
#
#  id              :integer          not null, primary key
#  practitioner_id :integer          not null
#  date            :date
#  sent_at         :datetime
#
# Indexes
#
#  index_daily_appointments_notifications_on_practitioner_id  (practitioner_id)
#

class DailyAppointmentsNotification < ApplicationRecord
  belongs_to :practitioner
end
