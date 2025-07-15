# == Schema Information
#
# Table name: treatment_template_sections
#
#  id          :integer          not null, primary key
#  template_id :integer          not null
#  name        :string
#  stype       :integer
#  sorder      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_treatment_template_sections_on_template_id  (template_id)
#

class TreatmentTemplateSection < ApplicationRecord
  belongs_to :treatment_template, inverse_of: :sections

  has_many :questions,
       class_name: 'TreatmentTemplateQuestion',
       foreign_key: :section_id,
       inverse_of: :treatment_template_section,
       dependent: :destroy

  accepts_nested_attributes_for :questions, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :name, :stype, :sorder
  validates_length_of :name, maximum: 100

  default_scope{order(sorder: :asc)}

end
