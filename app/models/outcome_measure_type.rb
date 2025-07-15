# == Schema Information
#
# Table name: outcome_measure_types
#
#  id           :integer          not null, primary key
#  business_id  :integer          not null
#  name         :string           not null
#  description  :text
#  outcome_type :string           not null
#  unit         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_outcome_measure_types_on_business_id  (business_id)
#

class OutcomeMeasureType < ApplicationRecord
  OUTCOME_TYPES = [
    OUTCOME_QUANTITATIVE = 'Quantitative',
    OUTCOME_QUALITATIVE  = 'Qualitative'
  ]

  belongs_to :business
  has_many :outcome_measures
  validates :name,
            presence: true,
            length: { maximum: 250 }

  validates :description,
            length: { maximum: 500 },
            allow_nil: true,
            allow_blank: true

  validates :outcome_type,
            presence: true,
            inclusion: { in: [OUTCOME_QUANTITATIVE] }

  validates :unit,
            presence: true,
            length: { maximum: 25 }
end
