# == Schema Information
#
# Table name: referrals
#
#  id                          :integer          not null, primary key
#  availability_type_id        :integer
#  profession                  :string
#  practitioner_id             :integer
#  patient_id                  :integer
#  business_id                 :integer
#  status                      :string
#  patient_attrs               :text
#  referrer_name               :string
#  referrer_phone              :string
#  referrer_email              :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  attachment_file_name        :string
#  attachment_content_type     :string
#  attachment_file_size        :integer
#  attachment_updated_at       :datetime
#  medical_note                :text
#  type                        :string
#  priority                    :string
#  contact_referrer_date       :date
#  contact_patient_date        :date
#  first_appoinment_date       :date
#  send_treatment_plan_date    :date
#  receive_referral_date       :date
#  summary_referral            :string
#  referrer_business_name      :string
#  professions                 :text
#  referral_reason             :text
#  archived_at                 :datetime
#  linked_contact_id           :integer
#  internal_note               :text
#  send_service_agreement_date :date
#  reject_reason               :string
#  approved_at                 :datetime
#  rejected_at                 :datetime
#
# Indexes
#
#  index_referrals_on_availability_type_id  (availability_type_id)
#  index_referrals_on_practitioner_id       (practitioner_id)
#

class Referral < ApplicationRecord
  include RansackAuthorization::Referral

  self.inheritance_column = nil

  auto_strip_attributes :medical_note,
                        :referral_reason,
                        :internal_note,
                        :summary_referral,
                        :priority,
                        :referrer_business_name,
                        :referrer_name,
                        :referrer_email,
                        :referrer_phone,
                        squish: true

  STATUS_PENDING = "Pending"
  STATUS_PENDING_MULTIPLE = "Pending Multiple"
  STATUS_APPROVED = "Approved"
  STATUS_REJECTED = "Rejected"

  PRIORITY_URGENT = 'Urgent'
  PRIORITY_NORMAL = 'Normal'

  STATUS = [
    STATUS_PENDING,
    STATUS_APPROVED,
    STATUS_REJECTED
  ]

  TYPES = [
    TYPE_GENERAL   = 'general',
    TYPE_HCP       = 'hcp',
    TYPE_DVA       = 'dva',
    TYPE_MEDICARE  = 'medicare',
    TYPE_NDIS      = 'ndis',
    TYPE_PRIVATE   = 'private',
    TYPE_HIH       = 'hih',
    TYPE_STRC      = 'strc',
    TYPE_SELF_REFERRAL = 'self_referral',
    TYPE_EXPANDED = 'expanded'
  ]

  THIRD_PARTY_REFERRAL_TYPES = [
    TYPE_DVA,
    TYPE_MEDICARE,
    TYPE_HCP,
    TYPE_NDIS,
    TYPE_PRIVATE,
    TYPE_HIH,
    TYPE_STRC
  ]

  belongs_to :patient, -> { with_deleted }
  belongs_to :practitioner
  belongs_to :business
  belongs_to :linked_contact, class_name: 'Contact'
  has_many :attachments, class_name: 'ReferralAttachment'

  has_and_belongs_to_many :businesses

  accepts_nested_attributes_for :patient
  accepts_nested_attributes_for :attachments, reject_if: :all_blank, allow_destroy: true
  serialize :patient_attrs, type: Hash
  serialize :professions, type: Array

  scope :not_archived, -> { where(archived_at: nil) }

  def archived?
    archived_at?
  end

  def availability_type
    AvailabilityType[availability_type_id]
  end

  def patient_name
    "#{patient_attrs[:first_name]} #{patient_attrs[:last_name]}".strip
  end

  def patient_address
    [patient_attrs[:address1], patient_attrs[:city], patient_attrs[:state], patient_attrs[:postcode]].
      map(&:presence).
      compact.
      join(', ')
  end

  def approved?
    status == STATUS_APPROVED
  end

  def rejected?
    status == STATUS_REJECTED
  end

  def pending?
    status == STATUS_PENDING
  end

  def pending_multiple?
    status == STATUS_PENDING_MULTIPLE
  end
end
