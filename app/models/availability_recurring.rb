# == Schema Information
#
# Table name: availability_recurrings
#
#  id              :integer          not null, primary key
#  practitioner_id :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  repeat_type     :string           default(""), not null
#  repeat_total    :integer          default(1), not null
#  repeat_interval :integer          default(1), not null
#
# Indexes
#
#  index_availability_recurrings_on_practitioner_id  (practitioner_id)
#

class AvailabilityRecurring < ApplicationRecord

  has_many :availabilities, foreign_key: :recurring_id
end
