# == Schema Information
#
# Table name: communications
#
#  id                :integer          not null, primary key
#  business_id       :integer          not null
#  practitioner_id   :integer
#  patient_id        :integer
#  message_type      :string
#  category          :string
#  direction         :string
#  message           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  contact_id        :integer
#  description       :text
#  content           :text
#  source_id         :integer
#  source_type       :string
#  recipient_type    :string
#  recipient_id      :integer
#  linked_patient_id :integer
#
# Indexes
#
#  index_communications_on_business_id                      (business_id)
#  index_communications_on_business_id_and_practitioner_id  (business_id,practitioner_id)
#  index_communications_on_contact_id                       (contact_id)
#  index_communications_on_patient_id                       (patient_id)
#  index_communications_on_practitioner_id                  (practitioner_id)
#  index_communications_on_practitioner_id_and_patient_id   (practitioner_id,patient_id)
#  index_communications_on_recipient_id_and_recipient_type  (recipient_id,recipient_type)
#  index_communications_on_source_type_and_source_id        (source_type,source_id)
#

class Communication < ApplicationRecord
  include RansackAuthorization::Communication
  MESSAGE_TYPES = [
    TYPE_EMAIL = 'Email',
    TYPE_SMS   = 'SMS'
  ]

  belongs_to :source, polymorphic: true
  belongs_to :recipient, -> { with_deleted }, polymorphic: true

  SOURCE_TYPES = [
    "Appointment", "Invoice", "AccountStatement", "PatientLetter", "Treatment", "PatientAttachment"
  ]

  CATEGORIES = [
    'general',
    # Appointment
    'appointment_reminder',
    'appointment_arrival_time',
    'appointment_confirmation',
    # Letter
    'letter_send',
    # Account statement
    'account_statement_send',
    # Invoice
    'invoice_send',
    'invoice_outstanding_reminder',
    'invoice_payment_remittance',

    # Patient attachment
    'patient_attachment_send',
    # Treatment note
    'treatment_note_send',
    # Practitioner on route
    'practitioner_on_route',

    'practitioner_sick_leave',

    # Satisfaction review request
    'satisfaction_review_request',

    # New patient confirmation,
    'new_patient_confirmation',

    # Uncategorized,
    'uncategorized'
  ]

  # TODO: validate message type, message length ..
  belongs_to :business
  belongs_to :practitioner, optional: true
  belongs_to :patient, -> { with_deleted }, optional: true
  belongs_to :contact, -> { with_deleted }, optional: true
  belongs_to :linked_patient, class_name: 'Patient'

  has_one :delivery, class_name: 'CommunicationDelivery', foreign_key: 'communication_id'

  validates_presence_of :business
  validates_inclusion_of :message_type, in: MESSAGE_TYPES

  validates :recipient, presence: true

  def sms?
    message_type == TYPE_SMS
  end

  def email?
    message_type == TYPE_EMAIL
  end
end
