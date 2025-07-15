# == Schema Information
#
# Table name: patient_cases
#
#  id              :integer          not null, primary key
#  notes           :text
#  status          :string
#  practitioner_id :integer
#  case_type_id    :integer
#  patient_id      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  invoice_total   :float
#  invoice_number  :integer
#  archived_at     :datetime
#  end_date        :date
#
# Indexes
#
#  index_patient_cases_on_case_type_id     (case_type_id)
#  index_patient_cases_on_patient_id       (patient_id)
#  index_patient_cases_on_practitioner_id  (practitioner_id)
#

class PatientCase < ApplicationRecord
  include RansackAuthorization::PatientCase
  STATUS_OPEN = "Open"
  STATUS_DISCHARGED = "Discharged"

  STATUS = [
    STATUS_OPEN,
    STATUS_DISCHARGED
  ]

  has_paper_trail(
    only: [
      :status, :case_type_id, :practitioner_id, :patient_id,
      :invoice_total, :invoice_number
    ],
    on: [:create, :update, :destroy],
    versions: {
      class_name: 'PaperTrailVersion'
    }
  )

  auto_strip_attributes :notes, squish: true

  after_initialize :set_default

  belongs_to :practitioner
  belongs_to :patient, -> { with_deleted }
  belongs_to :case_type, class_name: "CaseType"

  has_many :invoices
  has_many :treatments
  has_many :attachments, class_name: "PatientAttachment", foreign_key: 'patient_case_id'
  has_many :appointments, foreign_key: 'patient_case_id'

  validates :status, presence: true, inclusion: { in: STATUS }

  validates_presence_of :case_type, :patient
  validates_length_of :notes, maximum: 1000
  validates :end_date, timeliness: { type: :date },
            allow_nil: true,
            allow_blank: true

  accepts_nested_attributes_for :attachments, reject_if: :all_blank, allow_destroy: true

  scope :not_archived, -> { where(archived_at: nil) }
  scope :status_open, -> { where(status: STATUS_OPEN) }

  validates :invoice_number,
            numericality: { greater_than: 0, only_integer: true },
            allow_nil: true,
            allow_blank: true

  validates :invoice_total,
            numericality: { greater_than: 0 },
            format: { with: /\A\d+(?:\.\d{0,2})?\z/ },
            allow_nil: true,
            allow_blank: true

  def status_open?
    status == STATUS_OPEN
  end

  def archived?
    archived_at?
  end

  private

  def set_default
    self.status ||= STATUS_OPEN
  end
end
