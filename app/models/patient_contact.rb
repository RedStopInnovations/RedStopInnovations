# == Schema Information
#
# Table name: patient_contacts
#
#  id         :integer          not null, primary key
#  patient_id :integer          not null
#  contact_id :integer          not null
#  type       :string
#  primary    :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_patient_contacts_on_contact_id           (contact_id)
#  index_patient_contacts_on_patient_id           (patient_id)
#  index_patient_contacts_on_patient_id_and_type  (patient_id,type)
#

class PatientContact < ApplicationRecord
  self.inheritance_column = nil

  TYPES = [
    TYPE_DOCTOR      = 'Doctor',
    TYPE_SPECIALIST  = 'Specialist',
    TYPE_REFERRER    = 'Referrer',
    TYPE_INVOICE_TO  = 'Invoice to',
    TYPE_EMERGENCY   = 'Emergency',
    TYPE_OTHER       = 'Other'
  ]

  has_paper_trail(
    only: [
      :patient_id, :contact_id, :type
    ],
    on: [:create, :update, :destroy],
    versions: {
      class_name: 'PaperTrailVersion'
    }
  )

  belongs_to :patient, -> { with_deleted }, inverse_of: :patient_contacts, touch: true
  belongs_to :contact, -> { with_deleted }

  validates :type, presence: true, inclusion: { in: TYPES }
  validates :patient, :contact_id, presence: true
end
