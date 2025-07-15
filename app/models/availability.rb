# == Schema Information
#
# Table name: availabilities
#
#  id                        :integer          not null, primary key
#  name                      :string
#  start_time                :datetime
#  end_time                  :datetime
#  max_appointment           :integer
#  service_radius            :integer
#  address1                  :string
#  address2                  :string
#  city                      :string
#  state                     :string
#  postcode                  :string
#  country                   :string
#  latitude                  :float
#  longitude                 :float
#  practitioner_id           :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  business_id               :integer
#  group_id                  :string
#  fid                       :string           default(""), not null
#  allow_online_bookings     :boolean          default(TRUE), not null
#  recurring_id              :integer
#  availability_type_id      :integer
#  appointments_count        :integer          default(0)
#  contact_id                :integer
#  driving_distance          :decimal(10, 2)
#  description               :text
#  order_locked              :boolean          default(FALSE)
#  order_locked_by           :integer
#  hide                      :boolean          default(FALSE)
#  routing_status            :string
#  availability_subtype_id   :integer
#  group_appointment_type_id :integer
#  cached_stats              :jsonb
#  cached_stats_updated_at   :datetime
#
# Indexes
#
#  index_availabilities_on_allow_online_bookings   (allow_online_bookings)
#  index_availabilities_on_fid                     (fid)
#  index_availabilities_on_practitioner_id         (practitioner_id)
#  index_availabilities_on_recurring_id            (recurring_id)
#  index_business_id_and_availability_type_id      (business_id,availability_type_id)
#  index_practitioner_id_and_availability_type_id  (practitioner_id,availability_type_id)
#

class Availability < ApplicationRecord
  include HasAddressGeocoding
  include HasMarketplaceScope

  ROUTING_STATUS_OK = 'OK'
  ROUTING_STATUS_ERROR = 'ERROR'
  ROUTING_STATUS_NOT_FOUND = 'NOT_FOUND'

  has_paper_trail(
    only: [
      :name, :start_time, :end_time, :address1, :business_id, :practitioner_id,
      :availability_type_id, :contact_id, :recurring_id
    ],
    on: [:create, :update, :destroy],
    versions: {
      class_name: 'PaperTrailVersion'
    }
  )

  belongs_to :business
  belongs_to :practitioner
  belongs_to :contact, -> { with_deleted } # Facility only
  belongs_to :availability_subtype,
             class_name: 'AvailabilitySubtype',
             foreign_key: :availability_subtype_id

  belongs_to :group_appointment_type,
             class_name: 'AppointmentType',
             foreign_key: :group_appointment_type_id

  has_many :appointments, -> {
    where(cancelled_at: nil).
    order( order: :asc, id: :asc, start_time: :asc)
  }
  has_many :appointment_arrival_times, through: :appointments, source: :arrival_time # TODO: remove after arrival time update
  has_many :appointment_arrivals, through: :appointments, source: :arrival
  has_many :appointment_patients, through: :appointments, source: :patient
  has_and_belongs_to_many :contacts

  before_save :generate_friendly_id, if: :start_time_changed?

  scope :allow_online_bookings, -> { where allow_online_bookings: true }
  scope :not_hide, -> { where(hide: false) }
  scope :hide, -> { where(hide: true) }
  scope :home_visit, -> {
    where availability_type_id: AvailabilityType::TYPE_HOME_VISIT_ID
  }
  scope :facility, -> {
    where availability_type_id: AvailabilityType::TYPE_FACILITY_ID
  }
  scope :telehealth, -> {
    where availability_type_id: AvailabilityType::TYPE_TELEHEALTH_ID
  }
  scope :group_appointment, -> {
    where availability_type_id: AvailabilityType::TYPE_GROUP_APPOINTMENT_ID
  }
  scope :home_visit_or_facility, -> {
    where availability_type_id:[AvailabilityType::TYPE_HOME_VISIT_ID, AvailabilityType::TYPE_FACILITY_ID]
  }
  scope :appointment_availability, -> {
    where(availability_type_id: [
      AvailabilityType::TYPE_HOME_VISIT_ID,
      AvailabilityType::TYPE_FACILITY_ID,
      AvailabilityType::TYPE_GROUP_APPOINTMENT_ID
    ])
  }

  def recurring?
    recurring_id?
  end

  def availability_type
    @availability_type ||= AvailabilityType[availability_type_id]
  end

  def telehealth?
    availability_type_id == AvailabilityType::TYPE_TELEHEALTH_ID
  end

  def home_visit?
    availability_type_id == AvailabilityType::TYPE_HOME_VISIT_ID
  end

  def facility?
    availability_type_id == AvailabilityType::TYPE_FACILITY_ID
  end

  def non_billable?
    availability_type_id == AvailabilityType::TYPE_NON_BILLABLE_ID
  end

  def group_appointment?
    availability_type_id == AvailabilityType::TYPE_GROUP_APPOINTMENT_ID
  end

  def start_time_in_practitioner_timezone
    @start_time_in_practitioner_timezone ||= start_time.in_time_zone(practitioner.user_timezone)
  end

  def end_time_in_practitioner_timezone
    @end_time_in_practitioner_timezone ||= end_time.in_time_zone(practitioner.user_timezone)
  end

  def refresh_appointments_order
    Appointment.where(availability_id: id).
      where(cancelled_at: nil).
      order(order: :asc).
      to_a.
      each_with_index do |appt, index|
        appt.update_column :order, index
      end
  end

  private

  def generate_friendly_id
    pract_tz = practitioner.user.try(:timezone) || App::DEFAULT_TIME_ZONE
    start_time_in_pract_tz = start_time.in_time_zone(pract_tz)
    end_time_in_pract_tz = end_time.in_time_zone(pract_tz)

    self.fid = "AVAIL-" \
               "#{start_time_in_pract_tz.strftime('%d-%m-%y-%H%M')}" \
               ":#{end_time_in_pract_tz.strftime('%H%M')}"
  end
end
