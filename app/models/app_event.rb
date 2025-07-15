# == Schema Information
#
# Table name: app_events
#
#  id         :integer          not null, primary key
#  event_type :string           not null
#  data       :jsonb
#  created_at :datetime         not null
#
# Indexes
#
#  index_app_events_on_event_type  (event_type)
#

class AppEvent < ApplicationRecord
  TYPE_RCI = 'rci' # User clicked to reveal business's contact info(i.e. phone, mobile, email, website)
end
