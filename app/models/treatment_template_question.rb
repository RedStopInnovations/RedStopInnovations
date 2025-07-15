# == Schema Information
#
# Table name: treatment_template_questions
#
#  id         :integer          not null, primary key
#  section_id :integer          not null
#  name       :string
#  qtype      :integer
#  qorder     :integer
#  content    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_treatment_template_questions_on_section_id  (section_id)
#

class TreatmentTemplateQuestion < ApplicationRecord
  TYPE_SHORT_TEXT = 0
  TYPE_PARAGRAPH_TEXT = 1
  TYPE_CHECK_BOX = 2

  TYPES = [
    ["Short text", TYPE_SHORT_TEXT],
    ["Paragraph text", TYPE_PARAGRAPH_TEXT],
    ["Checkbox", TYPE_CHECK_BOX]
  ]

  belongs_to :treatment_template_section, inverse_of: :questions

  validates_presence_of :name, :qtype, :qorder
  validates_length_of :name, maximum: 100

  default_scope{order(qorder: :asc)}
end
