# == Schema Information
#
# Table name: practitioners
#
#  id                              :integer          not null, primary key
#  business_id                     :integer
#  first_name                      :string
#  last_name                       :string
#  profession                      :string
#  ahpra                           :string
#  medicare                        :string
#  phone                           :string
#  mobile                          :string
#  website                         :string
#  email                           :string
#  address1                        :string
#  address2                        :string
#  city                            :string
#  state                           :string
#  postcode                        :string
#  country                         :string
#  latitude                        :float
#  longitude                       :float
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  color                           :string           default("#3a87ad"), not null
#  summary                         :text
#  education                       :string
#  service_description             :text
#  availability                    :text
#  approved                        :boolean          default(FALSE)
#  slug                            :string           default(""), not null
#  driver_license                  :string
#  ahpra_registration              :string
#  medicare_provider_documentation :string
#  police_check                    :string
#  insurance_document              :string
#  video_url                       :string
#  clinic_name                     :string
#  clinic_website                  :string
#  clinic_phone                    :string
#  clinic_booking_url              :string
#  user_id                         :integer
#  active                          :boolean          default(TRUE), not null
#  full_name                       :string
#  signature_file_name             :string
#  signature_content_type          :string
#  signature_file_size             :integer
#  signature_updated_at            :datetime
#  rating_score                    :decimal(10, 2)   default(0.0), not null
#  sms_reminder_enabled            :boolean          default(TRUE)
#  metadata                        :jsonb
#  public_profile                  :boolean          default(TRUE)
#  allow_online_bookings           :boolean          default(TRUE)
#  local_latitude                  :float
#  local_longitude                 :float
#
# Indexes
#
#  idx_practitioners_approved_public_profile_active  (approved,public_profile,active)
#  index_practitioners_on_active                     (active)
#  index_practitioners_on_approved                   (approved)
#  index_practitioners_on_business_id                (business_id)
#  index_practitioners_on_slug                       (slug)
#  index_practitioners_on_user_id                    (user_id)
#

class Practitioner < ApplicationRecord
  include RansackAuthorization::Practitioner
  include HasAddressGeocoding

  PROFESSIONS = [
    "Physiotherapist",
    "Podiatrist",
    "Physical Therapist",
    "Chiropodist",
    "Occupational Therapist",
    "Psychologist",
    "Dietitian",
    "Exercise Physiologist",
    "Speech Therapist",
    "Social Worker",
    "Doctor",
    "Registered Nurse",
    "Enrolled Nurse",
    "Case Manager",
    "Massage Therapist",
    "Myotherapist",
    "Therapy Assistant",
    "Support Worker",
    "Acupuncturist",
    "Osteopath",
    "Chiropractor",
    "Diabetes Educator",
    "Optometrist",
    "Clinical Psychology",
    "Behaviour Support",
    "Art Therapist",
    "Music Therapist",
    "Paediatric Physiotherapist",
    "Hand Therapist"
  ]

  belongs_to :business, inverse_of: :practitioners
  belongs_to :user, inverse_of: :practitioner

  has_many :availabilities, dependent: :destroy
  has_many :appointments, inverse_of: :practitioner, dependent: :destroy
  has_many :invoices
  has_many :payments
  has_many :treatments
  has_many :posts, inverse_of: :practitioner
  has_many :reviews
  has_many :business_hours, class_name: 'PractitionerBusinessHour'

  has_and_belongs_to_many :tags
  has_and_belongs_to_many :billable_items
  has_and_belongs_to_many :public_billable_items,
                          -> {
                            where(billable_items: { display_on_pricing_page: :true, deleted_at: nil })
                          },
                          class_name: 'BillableItem'
  has_and_belongs_to_many(
    :most_10_expensive_billable_items,
    -> {
      not_deleted.
      where(billable_items: {display_on_pricing_page: :true}).
      order(price: :desc).
      limit(10)
    },
    class_name: 'BillableItem'
  )
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :appointment_types, validate: false
  has_many :documents, class_name: 'PractitionerDocument'

  has_attached_file :signature,
                    styles: {
                      medium: "300x150>",
                    },
                    convert_options: {
                      medium: "-quality 75 -strip"
                    }

  validates_attachment_content_type :signature, content_type: /\Aimage\/.*\z/
  validates_presence_of :user
  validates_presence_of :business
  validates_length_of :phone, :mobile, :education, :ahpra, :medicare, maximum: 250
  validates_length_of :summary, maximum: 5000

  validates :profession, inclusion: { in: PROFESSIONS }, allow_blank: true

  scope :approved, -> { where approved: true }
  scope :active, -> { where active: true }
  scope :public_profile, -> { where public_profile: true }
  scope :allow_online_bookings, -> { where(allow_online_bookings: true) }

  before_save :geocode_local_address, if: -> (pract) {
    (pract.city.present? && pract.city_changed?) || (pract.state.present? && pract.state_changed?)
  }

  delegate :email, :full_name, :first_name, :last_name, :timezone, to: :user, prefix: true

  def profile_picture_url(style = nil)
    user.avatar.url(style)
  end

  def profile_completed?
    user.avatar.exists? && profession.present? && summary.present? && address1.present?
  end

  def generate_slug
    "#{user.full_name.parameterize}-#{id}"
  end

  def refresh_avg_rating_score!
    scores = reviews.approved.pluck(:rating)
    avg_score =
      if scores.empty?
        0
      else
        (scores.inject(:+).to_f / scores.size).round(1)
      end
    update_column(:rating_score, avg_score)
  end

  private

  def geocode_local_address
    local_address = [city, state, country].join(' ')
    coords = Geocoder::coordinates(local_address)
    if coords.present?
      self.local_latitude = coords[0]
      self.local_longitude = coords[1]
    end

    true
  end
end
