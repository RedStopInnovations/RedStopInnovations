class Tag < ApplicationRecord
  include RansackAuthorization::Tag

  TYPE_PATIENT = 'Patient'.freeze

  belongs_to :business

  validates :name,
            presence: true,
            length: { maximum: 25 }

  validates :color,
            presence: true,
            length: { maximum: 7 }, # Hex color code length
            format: {
                with: /\A#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})\z/, message: 'must be a valid hex color code'
            }

  validates :tag_type, presence: true, inclusion: { in: %w[Patient] }
end
