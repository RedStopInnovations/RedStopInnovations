# == Schema Information
#
# Table name: treatments
#
#  id                    :integer          not null, primary key
#  appointment_id        :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  patient_id            :integer
#  practitioner_id       :integer
#  treatment_template_id :integer
#  name                  :string
#  print_name            :string
#  print_address         :boolean          default(FALSE)
#  print_birth           :boolean          default(FALSE)
#  print_ref_num         :boolean          default(FALSE)
#  print_doctor          :boolean          default(FALSE)
#  patient_case_id       :integer
#  status                :string
#  sections              :text
#  author_id             :integer
#  author_name           :string
#
# Indexes
#
#  index_treatments_on_appointment_id         (appointment_id)
#  index_treatments_on_author_id              (author_id)
#  index_treatments_on_patient_case_id        (patient_case_id)
#  index_treatments_on_patient_id             (patient_id)
#  index_treatments_on_treatment_template_id  (treatment_template_id)
#

# TODO: remove "print_***" columns
class Treatment < ApplicationRecord
  include RansackAuthorization::Treatment
  include PgSearch

  STATUS = [
    STATUS_DRAFT = "Draft",
    STATUS_FINAL = "Final"
  ]

  pg_search_scope :search_any_word,
                  against: :sections,
                  using: {
                    tsearch: { any_word: true }
                  }
  pg_search_scope :search_all_words,
                  against: :sections

  serialize :sections, type: Array

  belongs_to :practitioner # @TODO: remove
  belongs_to :patient, -> { with_deleted }
  belongs_to :appointment # optional?
  belongs_to :patient_case
  belongs_to :author, class_name: 'User'

  belongs_to :treatment_template,
             -> { with_deleted },
             class_name: 'TreatmentTemplate',
             foreign_key: :treatment_template_id,
             optional: true

  has_many :contents,
           class_name: 'TreatmentContent',
           foreign_key: :treatment_id,
           inverse_of: :treatment,
           dependent: :destroy

  accepts_nested_attributes_for :contents, reject_if: :all_blank, allow_destroy: true

  validates :status, inclusion: { in: STATUS }
  validates_presence_of :patient_id
  validates_presence_of :treatment_template_id, on: :create

  before_create :copy_name_from_template

  scope :final, -> { where(status: STATUS_FINAL) }
  scope :draft, -> { where(status: STATUS_DRAFT) }

  def simple_format_content
    content = ""

    sections.each do |section|
      content << section[:name] << "\n"
      next if section[:questions].blank?
      section[:questions].each do |question|
        if question[:answer].present? || (question[:answers].present?)
          if question[:type] == 'Checkboxes'
            if question[:answers].any? { |answer| answer[:selected] == '1' }
              if question[:name].present?
                content << question[:name] << "\n"
              end
              question[:answers].each do |answer|
                next if answer[:selected] != '1'
                content << answer[:content] << "\n"
              end
            end

          elsif question[:type] == 'Radiobuttons'
            if question[:answers].any? { |answer| answer[:selected] == '1' }
              if question[:name].present?
                content << question[:name] << "\n"
              end
              question[:answers].each do |answer|
                next if answer[:selected] != '1'
                content << answer[:content] << "\n"
              end
            end

          elsif question[:type] == 'Text'
            if question[:answer].try(:[], :content).present?
            content << question[:name] << "\n"
            content << question[:answer][:content] << "\n"
            end

          elsif question[:type] == 'Paragraph'
            if question[:answer].try(:[], :content).present?
              content << question[:name] << "\n"
              content << question[:answer][:content] << "\n"
            end

          elsif question[:type] == 'Integer'
            if question[:answer].try(:[], :content).present?
              content << question[:name] << "\n"
              content << question[:answer][:content] << "\n"
            end

          elsif question[:type] == 'Multiselect'
            if question[:answers].any? { |answer| answer[:selected] == '1' }
              if question[:name].present?
                content << question[:name] << "\n"
              end
              question[:answers].each do |answer|
                next if answer[:selected] != '1'
                content << answer[:content] << "\n"
              end
            end
          end

          content << "\n\n"
        end
      end

      content << "\n\n"
    end

    content
  end

  private

  def copy_name_from_template
    if treatment_template
      self.name = treatment_template.name
    end
  end
end
