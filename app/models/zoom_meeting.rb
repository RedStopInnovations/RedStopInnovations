# == Schema Information
#
# Table name: zoom_meetings
#
#  id              :integer          not null, primary key
#  practitioner_id :integer          not null
#  appointment_id  :integer          not null
#  zoom_meeting_id :string           not null
#  zoom_host_id    :string           not null
#  duration        :integer          not null
#  start_time      :datetime         not null
#  start_timezone  :string           not null
#  join_url        :string           not null
#  start_url       :text             not null
#  deleted_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_zoom_meetings_on_appointment_id   (appointment_id)
#  index_zoom_meetings_on_practitioner_id  (practitioner_id)
#

class ZoomMeeting < ApplicationRecord
  acts_as_paranoid

  belongs_to :appointment, -> { with_deleted }
  belongs_to :practitioner

  validates_presence_of :zoom_meeting_id, :zoom_host_id, :duration,
                        :start_time, :join_url, :start_url, :start_timezone
end
