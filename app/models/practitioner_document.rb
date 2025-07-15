# == Schema Information
#
# Table name: practitioner_documents
#
#  id                         :integer          not null, primary key
#  practitioner_id            :integer          not null
#  type                       :string           not null
#  document                   :string           not null
#  document_original_filename :string           not null
#  expiry_date                :date
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
# Indexes
#
#  index_practitioner_documents_on_practitioner_id  (practitioner_id)
#

class PractitionerDocument < ApplicationRecord
  self.inheritance_column = nil

  TYPES = [
    # TYPE_DRIVER_LICENSE = 'driver_license',
    TYPE_REGISTRATION   = 'registration',
    TYPE_INSURANCE      = 'insurance',
    TYPE_POLICE_CHECK   = 'police_check',
    TYPE_COVID_VACCINATION_CERTIFICATE = 'covid_vaccination_certificate',
    TYPE_FLU_VACCINATION_CERTIFICATE   = 'flu_vaccination_certificate',
    TYPE_NDIS_WORKER_SCREENING_CARD    = 'ndis_worker_screening_card',
    TYPE_CONTRACT    = 'contract',
  ]

  mount_uploader :document, PractitionerDocumentUploader

  belongs_to :practitioner

  validates :practitioner, presence: true
  validates :type,
            presence: true,
            inclusion: { in: TYPES }

  validates_uniqueness_of :type, scope: :practitioner_id

  validates_date :expiry_date, allow_nil: true, allow_blank: true

  scope :registration, -> { where(type: TYPE_REGISTRATION) }
  scope :insurance, -> { where(type: TYPE_INSURANCE) }
  scope :police_check, -> { where(type: TYPE_POLICE_CHECK) }

  def expired?
    expiry_date && expiry_date.past?
  end
end
