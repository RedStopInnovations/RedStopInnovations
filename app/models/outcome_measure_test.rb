# == Schema Information
#
# Table name: outcome_measure_tests
#
#  id                 :integer          not null, primary key
#  outcome_measure_id :integer          not null
#  date_performed     :date             not null
#  result             :float            not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_outcome_measure_id  (outcome_measure_id)
#

class OutcomeMeasureTest < ApplicationRecord
  belongs_to :outcome_measure, inverse_of: :tests

  validates_presence_of :outcome_measure, :date_performed

  validates_date :date_performed, allow_nil: true, allow_blank: true

  validates_uniqueness_of :date_performed, scope: :outcome_measure_id

  validates_numericality_of :result, greater_than: 0

  def result_formatted
    result % 1 == 0 ? result.to_i : result
  end
end
