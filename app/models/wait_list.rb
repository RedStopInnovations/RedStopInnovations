# == Schema Information
#
# Table name: wait_lists
#
#  id                  :integer          not null, primary key
#  business_id         :integer          not null
#  patient_id          :integer          not null
#  practitioner_id     :integer
#  date                :date             not null
#  profession          :string
#  appointment_type_id :integer
#  repeat_group_uid    :string
#  scheduled           :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  notes               :text
#
# Indexes
#
#  index_wait_lists_on_business_id      (business_id)
#  index_wait_lists_on_patient_id       (patient_id)
#  index_wait_lists_on_practitioner_id  (practitioner_id)
#

class WaitList < ApplicationRecord
  include RansackAuthorization::WaitList

  belongs_to :business
  belongs_to :patient, -> { with_deleted }
  belongs_to :practitioner, optional: true
  belongs_to :appointment_type, optional: true

  reverse_geocoded_by "patients.latitude", "patients.longitude"

  scope :not_scheduled, -> { where(scheduled: false) }
  scope :scheduled, -> { where(scheduled: true) }
end
