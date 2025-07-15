# == Schema Information
#
# Table name: bookings_questions
#
#  id          :integer          not null, primary key
#  business_id :integer          not null
#  order       :integer          not null
#  required    :boolean          default(FALSE), not null
#  title       :text
#  type        :string           not null
#  answers     :text
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_bookings_questions_on_business_id  (business_id)
#

class BookingsQuestion < ApplicationRecord
  self.inheritance_column = nil
  TYPES = %w(Text Checkboxes Radiobuttons)

  serialize :answers, type: Array
  belongs_to :business
  validates :title,
            presence: true,
            length: { maximum: 300 }
  validates :type,
            presence: true,
            inclusion: { in: %w(Text Checkboxes Radiobuttons) }

  validate do
    if !errors.key?(:type) &&
        %w(Checkboxes Radiobuttons).include?(type) &&
        (answers.length == 0)
      errors.add(:base, 'must have at least one answer.')
    end

    if answers.any? do |answer|
        answer[:content].to_s.length > 300
      end
      errors.add(:base, 'answer content is maximum by 300 characters.')
    end

    if answers.any? do |answer|
        answer[:content].to_s.strip.length == 0
      end
      errors.add(:base, 'answer content can\'t leave blank.')
    end
  end

  scope :not_deleted, -> { where(deleted_at: nil) }
end
