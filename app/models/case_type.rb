# == Schema Information
#
# Table name: case_types
#
#  id          :integer          not null, primary key
#  title       :string
#  business_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#  description :text
#

class CaseType < ApplicationRecord
  include RansackAuthorization::CaseType

  belongs_to :business
  has_many :patient_cases

  auto_strip_attributes :description, squish: true

  validates :title,
            presence: true,
            length: { maximum: 250 }

  validates :description,
            length: { maximum: 500 },
            allow_blank: true,
            allow_nil: true

  scope :not_deleted, -> { where(deleted_at: nil) }

  def deleted?
    deleted_at?
  end
end
