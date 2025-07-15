# == Schema Information
#
# Table name: communication_templates
#
#  id            :integer          not null, primary key
#  business_id   :integer          not null
#  email_subject :text
#  content       :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  name          :string           default(""), not null
#  template_id   :string           default(""), not null
#  enabled       :boolean          default(TRUE)
#  settings      :json
#
# Indexes
#
#  index_business_id_and_template_id             (business_id,template_id)
#  index_communication_templates_on_business_id  (business_id)
#

class CommunicationTemplate < ApplicationRecord
  SMS_TEMPLATE_IDS = [
    TEMPLATE_ID_APPOINTMENT_ARRIVAL_TIME   = 'appointment_arrival_time',
    TEMPLATE_ID_APPOINTMENT_REMINDER_SMS   = 'appointment_reminder_sms',
    TEMPLATE_ID_PRACTITIONER_ON_ROUTE_SMS  = 'practitioner_on_route_sms',
    TEMPLATE_ID_APPOINTMENT_REMINDER_1WEEK = 'appointment_reminder_sms_1week'
  ]

  EMAIL_TEMPLATE_IDS = [
    TEMPLATE_ID_APPOINTMENT_CONFIRMATION      = 'appointment_confirmation',
    TEMPLATE_ID_SEND_INVOICE_PDF              = 'send_invoice_pdf',
    TEMPLATE_ID_APPOINTMENT_REMINDER          = 'appointment_reminder',
    TEMPLATE_ID_OUTSTANDING_INVOICE_REMINDER  = 'outstanding_invoice_reminder',
    TEMPLATE_ID_NEW_PATIENT_CONFIRMATION      = 'new_patient_confirmation',
    TEMPLATE_ID_SATISFACTION_REVIEW_REQUEST   = 'satisfaction_review_request',
    TEMPLATE_ID_INVOICE_PAYMENT_REMITTANCE    = 'invoice_payment_remittance'
  ]

  belongs_to :business
  has_many :attachments, class_name: 'CommunicationAttachment'

  accepts_nested_attributes_for :attachments, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :content

  validates :email_subject,
            presence: true,
            length: { minimum: 10, maximum: 250 },
            if: :is_email_template?

  validate do
    if SMS_TEMPLATE_IDS.include?(template_id) && content.size > 500
      errors.add(:content, 'content is too long. Maximum is 500 characters.')
    end
  end

  def is_email_template?
    EMAIL_TEMPLATE_IDS.include? template_id
  end

  def is_appointment_template?
    [
      TEMPLATE_ID_APPOINTMENT_ARRIVAL_TIME,
      TEMPLATE_ID_APPOINTMENT_CONFIRMATION,
      TEMPLATE_ID_APPOINTMENT_REMINDER,
      TEMPLATE_ID_APPOINTMENT_REMINDER_SMS,
      TEMPLATE_ID_SATISFACTION_REVIEW_REQUEST,
      TEMPLATE_ID_PRACTITIONER_ON_ROUTE_SMS,
      TEMPLATE_ID_APPOINTMENT_REMINDER_1WEEK
    ].include?(template_id)
  end

  def is_invoice_template?
    [
      TEMPLATE_ID_OUTSTANDING_INVOICE_REMINDER,
      TEMPLATE_ID_SEND_INVOICE_PDF,
      TEMPLATE_ID_INVOICE_PAYMENT_REMITTANCE
    ].include?(template_id)
  end

  def is_sms_template?
    SMS_TEMPLATE_IDS.include? template_id
  end
end
