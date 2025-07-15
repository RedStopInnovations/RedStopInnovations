# == Schema Information
#
# Table name: reviews
#
#  id                    :integer          not null, primary key
#  practitioner_id       :integer
#  patient_id            :integer
#  rating                :integer
#  comment               :text
#  publish_rating        :boolean          default(TRUE)
#  publish_comment       :boolean          default(TRUE)
#  approved              :boolean          default(FALSE)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  patient_name          :string           default(""), not null
#  source_appointment_id :integer
#
# Indexes
#
#  index_reviews_on_patient_id       (patient_id)
#  index_reviews_on_practitioner_id  (practitioner_id)
#

class Review < ApplicationRecord
  belongs_to :practitioner
  belongs_to :patient, -> { with_deleted }, optional: true
  scope :approved, -> { where approved: true }

  validates_presence_of :rating, :comment, :patient_name, :practitioner
  validates :rating, presence: true, numericality: { greater_than: 0}
  validates_length_of :comment, maximum: 1000

  after_commit do
    practitioner.refresh_avg_rating_score!
  end
end
