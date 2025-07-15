# == Schema Information
#
# Table name: treatment_contents
#
#  id           :integer          not null, primary key
#  treatment_id :integer          not null
#  section_id   :integer          not null
#  question_id  :integer          not null
#  content      :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  sname        :string
#  sorder       :integer
#  qname        :string
#  qtype        :integer
#  qorder       :integer
#
# Indexes
#
#  index_treatment_contents_on_question_id   (question_id)
#  index_treatment_contents_on_section_id    (section_id)
#  index_treatment_contents_on_treatment_id  (treatment_id)
#

class TreatmentContent < ApplicationRecord
  belongs_to :treatment, inverse_of: :contents
  belongs_to :section,  class_name: 'TreatmentTemplateSection',  foreign_key: :section_id
  belongs_to :question, class_name: 'TreatmentTemplateQuestion', foreign_key: :question_id

  default_scope{order(sorder: :asc, qorder: :asc)}
end
