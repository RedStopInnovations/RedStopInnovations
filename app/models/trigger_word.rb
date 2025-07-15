# == Schema Information
#
# Table name: trigger_words
#
#  id             :integer          not null, primary key
#  category_id    :integer          not null
#  text           :string           not null
#  mentions_count :integer
#  patients_count :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_trigger_words_on_category_id  (category_id)
#

class TriggerWord < ApplicationRecord
  belongs_to :category, class_name: 'TriggerCategory', counter_cache: :words_count
  has_one :trigger_report, as: :trigger_source, dependent: :delete

  validates_presence_of :text

  validates :text,
            presence: true,
            length: {
              minimum: 2, maximum: 50
            }

  after_commit :update_trigger_report, on: [:create, :update], if: proc { |record|
    record.previous_changes.key?(:text)
  }

  after_commit on: [:destroy] do
    Trigger::CategoryReportWorker.perform_later(category_id)
  end

  private

  def update_trigger_report
    Trigger::WordReportWorker.perform_later(id)
    Trigger::CategoryReportWorker.perform_later(category_id)
  end
end
