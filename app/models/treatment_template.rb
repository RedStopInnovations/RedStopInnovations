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
  serialize :template_sections, type: Array

  belongs_to :business
  has_and_belongs_to_many :users, validate: false
  validates_presence_of :name
  validates_length_of :name, maximum: 100

  before_save :update_cached_counters

  private

  def update_cached_counters
    if template_sections.present?
      self.sections_count = template_sections.count
      self.questions_count = template_sections.map do |section|
        section[:questions].count
      end.reduce(&:+)
    else
      self.sections_count = 0
      self.questions_count = 0
    end
  end
end
