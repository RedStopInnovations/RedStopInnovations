# == Schema Information
#
# Table name: treatments
#
#  id                           :integer          not null, primary key
#  appointment_id               :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  patient_id                   :integer
#  treatment_note_template_id   :integer
#  name                         :string
#  patient_case_id              :integer
#  status                       :string
#  sections                     :text
#  author_id                    :integer
#  author_name                  :string
#
# Indexes
#
#  index_treatments_on_appointment_id         (appointment_id)
#  index_treatments_on_author_id              (author_id)
#  index_treatments_on_patient_case_id        (patient_case_id)
#  index_treatments_on_patient_id             (patient_id)
#  index_treatments_on_treatment_note_template_id  (treatment_note_template_id)
#

class Treatment < ApplicationRecord
  include RansackAuthorization::Treatment
  include PgSearch

  STATUS = [
    STATUS_DRAFT = "Draft",
    STATUS_FINAL = "Final"
  ]

  belongs_to :patient, -> { with_deleted }
  belongs_to :appointment, optional: true
  belongs_to :patient_case, optional: true
  belongs_to :author, class_name: 'User', optional: true

  belongs_to :treatment_note_template, optional: true

  validates :status, inclusion: { in: STATUS }
  validates_length_of :name,
                      maximum: 255,
                      allow_blank: true,
                      allow_nil: true

  scope :final, -> { where(status: STATUS_FINAL) }
  scope :draft, -> { where(status: STATUS_DRAFT) }
end
