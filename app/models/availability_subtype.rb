# == Schema Information
#
# Table name: availability_subtypes
#
#  id          :bigint           not null, primary key
#  business_id :integer          not null
#  name        :string
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_availability_subtypes_on_business_id  (business_id)
#
class AvailabilitySubtype < ApplicationRecord
  auto_strip_attributes :name

  belongs_to :business

  validates :name,
            presence: true,
            format: {
              with: /\A[a-zA-Z0-9\s]+\z/i, message: 'can only contain letters and numbers'
            },
            length: { minimum: 2, maximum: 50 }

  scope :not_deleted, -> { where(deleted_at: nil) }
end
