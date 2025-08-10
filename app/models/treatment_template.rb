# == Schema Information
#
# Table name: treatment_templates
#
#  id                :integer          not null, primary key
#  business_id       :integer          not null
#  name              :string
#  print_name        :string
#  print_address     :boolean
#  print_birth       :boolean
#  print_ref_num     :boolean
#  print_doctor      :boolean
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  deleted_at        :datetime
#  template_sections :text
#  sections_count    :integer          default(0)
#  questions_count   :integer          default(0)
#
# Indexes
#
#  index_treatment_templates_on_business_id  (business_id) WHERE (deleted_at IS NULL)
#

class TreatmentTemplate < ApplicationRecord
  include DeletionRecordable
  acts_as_paranoid

  QUESTION_TYPES = [
    'Text',
    'Paragraph',
    'Checkboxes',
    'Radiobuttons',
    'Integer',
    'Multiselect'
  ]

  belongs_to :business
  validates_presence_of :name
  validates_length_of :name, maximum: 255
end
