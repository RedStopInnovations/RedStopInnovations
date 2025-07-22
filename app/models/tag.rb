class Tag < ApplicationRecord
  include RansackAuthorization::Tag

  TYPE_PATIENT = 'Patient'.freeze

  belongs_to :business
  has_and_belongs_to_many :patients

  validates :name,
            presence: true,
            length: { maximum: 50 }

  validates :color,
            presence: true,
            length: { maximum: 7 }, # Hex color code length
            format: {
                with: /\A#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})\z/, message: 'must be a valid hex color code'
            }

  validates :tag_type, presence: true, inclusion: { in: %w[Patient] }

  scope :type_patient, -> { where(tag_type: TYPE_PATIENT) }
end
