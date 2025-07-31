# == Schema Information
#
# Table name: patients
#
#  id                      :integer          not null, primary key
#  first_name              :string
#  middle_name             :string
#  last_name               :string
#  phone                   :string
#  mobile                  :string
#  website                 :string
#  fax                     :string
#  email                   :string
#  address1                :string
#  address2                :string
#  city                    :string
#  state                   :string
#  postcode                :string
#  country                 :string
#  latitude                :float
#  longitude               :float
#  dob                     :date
#  gender                  :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  timezone                :string           default("Australia/Brisbane")
#  reminder_enable         :boolean          default(TRUE)
#  archived_at             :datetime
#  deleted_at              :datetime
#  medipass_member_id      :string
#  import_id               :integer
#  full_name               :string
#  xero_contact_id         :string
#  general_info            :text
#  phone_formated          :string
#  mobile_formated         :string
#  next_of_kin             :text
#  medicare_details        :jsonb
#  dva_details             :jsonb
#  business_id             :integer          default(0), not null
#  accepted_privacy_policy :boolean
#  nationality             :string
#  aboriginal_status       :string
#  spoken_languages        :string
#  ndis_details            :jsonb
#  hcp_details             :jsonb
#  hih_details             :jsonb
#  hi_details              :jsonb
#  important_notification  :text
#  strc_details            :jsonb
#  medications             :jsonb
#  allergies               :jsonb
#  intolerances            :jsonb
#
# Indexes
#
#  index_patients_on_deleted_at  (deleted_at)
#

class Patient < ApplicationRecord
  include RansackAuthorization::Patient
  include HasAddressGeocoding
  include PatientContactTagging
  include DeletionRecordable

  acts_as_paranoid
  auto_strip_attributes :first_name, :last_name, squish: true
  auto_strip_attributes :phone, :mobile, :email, :gender, :next_of_kin, :nationality,
                        :aboriginal_status, :spoken_languages, :important_notification,
                        nullify: true

  has_paper_trail(
    only: [
      :first_name, :last_name, :email, :phone, :mobile, :dob,
      :address1, :address2, :city, :state, :postcode, :country, :reminder_enable, :archived_at
    ],
    on: [:create, :update, :destroy],
    versions: {
      class_name: 'PaperTrailVersion'
    }
  )

  store_accessor :medicare_details,
                 :medicare_card_number,
                 :medicare_card_irn,
                 :medicare_referrer_name,
                 :medicare_referrer_provider_number,
                 :medicare_referral_date

  store_accessor :dva_details,
                 :dva_file_number,
                 :dva_card_type,
                 :dva_hospital,
                 :dva_white_card_disability,
                 :dva_referrer_name,
                 :dva_referrer_provider_number,
                 :dva_referral_date

  # NDIS details
  store_accessor :ndis_details,
                 :ndis_client_number,
                 :ndis_plan_start_date,
                 :ndis_plan_end_date,
                 :ndis_plan_manager_name,
                 :ndis_plan_manager_phone,
                 :ndis_plan_manager_email,
                 :ndis_fund_management,
                 :ndis_diagnosis

  # Home care package details
  store_accessor :hcp_details,
                 :hcp_company_name,
                 :hcp_manager_name,
                 :hcp_manager_phone,
                 :hcp_manager_email

  # Hospital in the home details
  store_accessor :hih_details,
                 :hih_hospital,
                 :hih_procedure,
                 :hih_discharge_date,
                 :hih_surgery_date,
                 :hih_doctor_name,
                 :hih_doctor_phone,
                 :hih_doctor_email

  # Health insurance details
  store_accessor :hi_details,
                 :hi_company_name,
                 :hi_number,
                 :hi_patient_number,
                 :hi_manager_name,
                 :hi_manager_email,
                 :hi_manager_phone

  # STRC details
  store_accessor :strc_details,
                 :strc_company_name,
                 :strc_company_phone,
                 :strc_invoice_to_name,
                 :strc_invoice_to_email

  GENDERS = [
    "Male",
    "Female",
    "Undisclosed",
  ]

  belongs_to :business

  has_many :patient_cases
  has_many :appointments
  has_many :incoming_messages
  has_many :invoices
  has_many :payments
  has_many :treatments
  has_many :attachments, class_name: 'PatientAttachment', inverse_of: :patient
  has_many :wait_lists
  has_one  :stripe_info, dependent: :destroy # @TODO: remove
  has_many :letters, class_name: 'PatientLetter', inverse_of: :patient
  has_many :id_numbers, class_name: 'PatientIdNumber', inverse_of: :patient
  has_many :reviews
  has_many :outcome_measures
  has_many :patient_accesses
  has_many :account_statements, as: :source
  has_many :tasks
  has_one :stripe_customer, class_name: 'PatientStripeCustomer', inverse_of: :patient
  has_and_belongs_to_many :tags

  accepts_nested_attributes_for :patient_contacts, allow_destroy: true

  before_save :set_full_name_attr, :format_phone_and_mobile
  before_save :strip_medicare_details,
              :strip_dva_details,
              :strip_ndis_details,
              :strip_hcp_details,
              :strip_hih_details,
              :strip_hi_details,
              :strip_strc_details

  scope :not_archived, -> { where(archived_at: nil) }

  # TODO: remove this shit
  def full_name
    [first_name.try(:strip), last_name.try(:strip)].compact.join(' ')
  end

  def imported?
    !import_id.nil?
  end

  def archived?
    archived_at?
  end

  def archive
    update_columns(
     archived_at: Time.current,
     updated_at: Time.current
    )
  end

  def unarchive
    update_columns(
     archived_at: nil,
     updated_at: Time.current
    )
  end

  def male?
    gender == 'Male'
  end

  def female?
    gender == 'Female'
  end

  private

  def set_full_name_attr
    if first_name_changed? || last_name_changed?
      self.full_name = [
        first_name.to_s.strip.presence,
        last_name.to_s.strip.presence
      ].compact.join(' ').strip
    end
  end

  def format_phone_and_mobile
    if phone.present?
      self.phone_formated = TelephoneNumber.parse(phone, country).e164_number
    else
      self.phone_formated = nil
    end

    if mobile.present?
      self.mobile_formated = TelephoneNumber.parse(mobile, country).e164_number
    else
      self.mobile_formated = nil
    end

    {
      mobile_formated: self.mobile_formated,
      phone_formated: self.phone_formated
    }
  end

  def strip_medicare_details
    stripped_medicare = {}

    if medicare_details.present?
      medicare_details.each_pair do |k, v|
        if v.present?
          stripped_medicare[k] = v
        end
      end
    end

    self.medicare_details = stripped_medicare.presence
  end

  def strip_dva_details
    stripped_dva = {}
    if dva_details.present?
      dva_details.each_pair do |k, v|
        if v.present?
          stripped_dva[k] = v
        end
      end
    end

    self.dva_details = stripped_dva.presence
  end

  def strip_ndis_details
    stripped_ndis = {}
    if ndis_details.present?
      ndis_details.each_pair do |k, v|
        if v.present?
          stripped_ndis[k] = v
        end
      end
    end

    self.ndis_details = stripped_ndis.presence
  end

  def strip_hcp_details
    stripped_hcp = {}
    if hcp_details.present?
      hcp_details.each_pair do |k, v|
        if v.present?
          stripped_hcp[k] = v
        end
      end
    end

    self.hcp_details = stripped_hcp.presence
  end

  def strip_hih_details
    stripped_hih = {}
    if hih_details.present?
      hih_details.each_pair do |k, v|
        if v.present?
          stripped_hih[k] = v
        end
      end
    end

    self.hih_details = stripped_hih.presence
  end

  def strip_hi_details
    stripped_hi = {}
    if hi_details.present?
      hi_details.each_pair do |k, v|
        if v.present?
          stripped_hi[k] = v
        end
      end
    end

    self.hi_details = stripped_hi.presence
  end

  def strip_strc_details
    stripped_strc = {}
    if strc_details.present?
      strc_details.each_pair do |k, v|
        if v.present?
          stripped_strc[k] = v
        end
      end
    end

    self.strc_details = stripped_strc.presence
  end
end
