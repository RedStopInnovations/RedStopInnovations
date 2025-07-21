# == Schema Information
#
# Table name: businesses
#
#  id                  :integer          not null, primary key
#  name                :string
#  phone               :string
#  mobile              :string
#  website             :string
#  fax                 :string
#  email               :string
#  address1            :string
#  address2            :string
#  city                :string
#  state               :string
#  postcode            :string
#  country             :string
#  latitude            :float
#  longitude           :float
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  avatar_file_name    :string
#  avatar_content_type :string
#  avatar_file_size    :integer
#  avatar_updated_at   :datetime
#  bank_name           :string
#  bank_branch_number  :string
#  bank_account_name   :string
#  bank_account_number :string
#  abn                 :string
#  is_partner          :boolean          default(FALSE)
#  active              :boolean          default(FALSE)
#  currency            :string           default("aud")
#  policy_url          :string
#  suspended           :boolean          default(FALSE)
#  accounting_email    :string
#
# Indexes
#
#  index_businesses_on_active          (active)
#  index_businesses_on_is_partner      (is_partner)
#

class Business < ApplicationRecord
  include RansackAuthorization::Business
  include HasAddressGeocoding

  auto_strip_attributes :name, :bank_branch_number, :bank_account_name, :bank_account_number, :abn, :accounting_email, :email

  has_attached_file(
    :avatar,
    styles: { medium: "300x300>", thumb: "100x100>" },
    default_url: -> (attachment) {
      ActionController::Base.helpers.asset_path('default-avatar.png')
    }
  )
  belongs_to :marketplace, optional: true
  has_many :communications
  has_many :practitioners, inverse_of: :business
  has_many :active_practitioners,
           -> { where(active: true).includes(:user) },
           class_name: 'Practitioner'
  has_many :appointments, through: :practitioners
  has_many :treatments, through: :practitioners

  has_many :patients
  has_many :invoices
  has_many :payments
  has_many :posts, through: :practitioners
  has_many :reviews, through: :practitioners
  has_many :invoice_shortcuts
  has_many :conversations, class_name: 'ConversationRoom'
  has_many :appointment_types, inverse_of: :business
  has_many :users
  has_many :treatments, through: :users
  has_many :billable_items
  has_many :treatment_templates
  has_many :treatment_shortcuts
  has_many :tasks
  has_many :outcome_measure_types
  has_many :products
  has_many :payment_types
  has_many :groups
  has_many :case_types
  has_many :patient_cases, through: :case_types
  has_many :incoming_messages, through: :patients
  has_many :availabilities
  has_many :contacts
  has_many :taxes
  has_many :letter_templates
  has_many :patient_letters
  has_many :provider_number_registrations
  has_one  :subscription
  has_many :business_invoices
  has_many :subscription_payments
  has_many :communication_templates
  has_many :wait_lists
  has_many :account_statements
  has_many :patient_account_statements,
           -> { where(source_type: 'Patient') },
           class_name: 'AccountStatement'

  has_many :contact_account_statements,
            -> { where(source_type: 'Contact') },
            class_name: 'AccountStatement'

  has_many :bookings_questions
  has_many :trigger_categories
  has_many :trigger_words, through: :trigger_categories, source: :words
  has_many :availability_subtypes, class_name: 'AvailabilitySubtype'
  has_many :patient_treatments, through: :patients, source: :treatments

  has_one :stripe_account, class_name: 'BusinessStripeAccount'
  has_one :mailchimp_setting, class_name: 'BusinessMailchimpSetting'
  has_one :medipass_account, class_name: 'BusinessMedipassAccount', inverse_of: :business
  has_one :tutorial, class_name: "BusinessTutorial"
  has_one :invoice_setting
  has_one :patient_access_setting
  has_one :claiming_auth_group
  has_one :setting, class_name: 'BusinessSetting'
  has_one :physitrack_integration
  has_one :calendar_appearance_setting

  has_and_belongs_to_many :referrals

  validates_presence_of :name

  validates_length_of :name,
                      maximum: 150,
                      allow_nil: true,
                      allow_blank: true

  validates_length_of :abn,
                      maximum: 50,
                      allow_nil: true,
                      allow_blank: true

  # TODO: update valid length for each bank field
  validates_length_of :bank_name,
                      :bank_branch_number,
                      :bank_account_name,
                      :bank_account_number,
                      maximum: 255,
                      allow_nil: true,
                      allow_blank: true
  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\z/

  validates :email, email: :true, allow_blank: true, allow_nil: true
  validates :accounting_email, email: :true, allow_blank: true, allow_nil: true

  validates_format_of :website, with: URI.regexp, allow_blank: true, allow_nil: true
  validates_length_of :phone, :fax, :website, maximum: 250

  validates_format_of :policy_url,
                      with: URI.regexp,
                      allow_blank: true,
                      allow_nil: true

  before_save :set_currency

  scope :active, -> { where active: true }

  def in_trial_period?
    self.subscription.trial_end.future?
  end

  def subscription_appointment_price
    self.subscription.subscription_plan.appointment_price unless self.subscription.nil?
  end

  def subscription_sms_price
    self.subscription.subscription_plan.sms_price unless self.subscription.nil?
  end

  def subscription_credit_card_added?
    self.subscription && self.subscription.stripe_customer_id.present?
  end

  def get_communication_template(template_id)
    communication_templates.find_by(template_id: template_id)
  end

  def communication_template_enabled?(template_id)
    !!get_communication_template(template_id).try(:enabled)
  end

  def stripe_payment_available?
    stripe_account.present?
  end

  def medipass_payment_available?
    medipass_account.present?
  end

  def mailchimp_list_sync_ready?
    mailchimp_setting.present? && mailchimp_setting.settings_completed?
  end

  def patient_access_enable?
    patient_access_setting.present? && patient_access_setting.enable?
  end

  def physitrack_integration_enabled?
    physitrack_integration.present? && physitrack_integration.enabled?
  end

  private

  def set_currency
    if country_changed?
      country_info = ISO3166::Country.new self.country
      currency = country_info&.currency&.iso_code || App::DEFAULT_CURRENCY

      self.currency = currency
    end
  end
end
