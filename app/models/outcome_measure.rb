# == Schema Information
#
# Table name: outcome_measures
#
#  id                      :integer          not null, primary key
#  patient_id              :integer          not null
#  outcome_measure_type_id :integer          not null
#  practitioner_id         :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class OutcomeMeasure < ApplicationRecord
  belongs_to :patient, -> { with_deleted }
  belongs_to :outcome_measure_type
  belongs_to :practitioner

  has_many :tests,
           class_name: 'OutcomeMeasureTest',
           inverse_of: :outcome_measure,
           dependent: :delete_all

  validates_presence_of :patient,
                        :practitioner,
                        :outcome_measure_type
end
