# == Schema Information
#
# Table name: appointments
#
#  id                       :integer          not null, primary key
#  practitioner_id          :integer          not null
#  patient_id               :integer          not null
#  appointment_type_id      :integer          not null
#  start_time               :datetime
#  end_time                 :datetime
#  notes                    :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  availability_id          :integer
#  first_reminder_mail_sent :boolean          default(FALSE)
#  fid                      :string           default(""), not null
#  booked_online            :boolean          default(FALSE), not null
#  deleted_at               :datetime
#  is_completed             :boolean          default(FALSE)
#  order                    :integer          default(0)
#  cancelled_at             :datetime
#  break_times              :integer
#  public_token             :string
#  status                   :string
#  one_week_reminder_sent   :boolean          default(FALSE)
#  is_confirmed             :boolean          default(FALSE)
#  is_invoice_required      :boolean          default(TRUE)
#  patient_case_id          :integer
#  cancelled_by_id          :integer
#
# Indexes
#
#  index_appointments_on_appointment_type_id  (appointment_type_id)
#  index_appointments_on_availability_id      (availability_id)
#  index_appointments_on_created_at           (created_at)
#  index_appointments_on_deleted_at           (deleted_at)
#  index_appointments_on_fid                  (fid)
#  index_appointments_on_patient_case_id      (patient_case_id)
#  index_appointments_on_patient_id           (patient_id)
#  index_appointments_on_practitioner_id      (practitioner_id)
#  index_appointments_on_start_time           (start_time)
#
class Appointment < ApplicationRecord
  include DeletionRecordable
  include RansackAuthorization::Appointment

  acts_as_paranoid
  has_secure_token :public_token

  has_paper_trail(
    only: [
      :start_time, :end_time, :practitioner_id, :appointment_type_id,
      :availability_id, :booked_online, :status, :is_confirmed, :is_invoice_required, :patient_case_id,
      :cancelled_at, :deleted_at
    ],
    on: [:create, :update, :destroy],
    versions: {
      class_name: 'PaperTrailVersion'
    }
  )

  has_one :created_version, -> { where(event: 'create') },
    class_name: 'PaperTrailVersion',
    as: :item

  has_one :deleted_version, -> { where(event: 'destroy') },
    class_name: 'PaperTrailVersion',
    as: :item

  has_many_attached :attendance_proofs

  STATUSES = [
    STATUS_COMPLETED = 'completed',
    STATUS_CLIENT_NOT_HOME = 'client not home',
    STATUS_CLIENT_UNWELL = 'client unwell',
    STATUS_CLIENT_NOT_REQUIRED = 'not required',
    STATUS_CLIENT_LATE_CANCEL_BY_CLIENT = 'late cancel by client',
    # OPTIMIZE: allow user to manage thier own appointment statuses
    STATUS_OVERTIME = 'overtime',
    STATUS_EXTRA_PAY = 'extra pay'
  ]

  belongs_to :practitioner, inverse_of: :appointments
  belongs_to :patient, -> { with_deleted }
  belongs_to :appointment_type
  belongs_to :availability, counter_cache: true
  belongs_to :patient_case
  belongs_to :cancelled_by_user, class_name: 'User', foreign_key: :cancelled_by_id

  has_one :invoice
  has_one :treatment_note
  has_one :zoom_meeting
  has_one :arrival_time, class_name: 'AppointmentArrivalTime' # TODO: remove after arrival time update
  has_one :arrival, class_name: 'AppointmentArrival'
  has_many :subscription_billings
  has_many :bookings_answers, class_name: 'AppointmentBookingsAnswer'

  before_save :generate_friendly_id, if: :start_time_changed?

  scope :booked_online, -> { where(booked_online: true) }
  scope :not_cancelled, -> { where(cancelled_at: nil) }

  def telehealth?
    appointment_type&.availability_type&.id == AvailabilityType::TYPE_TELEHEALTH_ID
  end

  def home_visit?
    appointment_type&.availability_type&.id == AvailabilityType::TYPE_HOME_VISIT_ID
  end

  def facility?
    appointment_type&.availability_type&.id == AvailabilityType::TYPE_FACILITY_ID
  end

  def group_appointment?
    appointment_type&.availability_type&.id == AvailabilityType::TYPE_GROUP_APPOINTMENT_ID
  end

  def cancel
    update_attribute :cancelled_at, Time.current
    Availability.reset_counters availability_id, 'appointments_count'
  end

  def completed?
    is_completed?
  end

  def status_completed?
    status == STATUS_COMPLETED
  end

  def start_time_in_practitioner_timezone
    start_time.in_time_zone(practitioner.user_timezone)
  end

  def end_time_in_practitioner_timezone
    end_time.in_time_zone(practitioner.user_timezone)
  end

  def business
    practitioner.business
  end

  def associated_patient_id
    patient.id
  end

  private

  def generate_friendly_id
    pract_tz = practitioner.user.try(:timezone) || App::DEFAULT_TIME_ZONE
    start_time_in_pract_tz = start_time.in_time_zone(pract_tz)
    end_time_in_pract_tz = end_time.in_time_zone(pract_tz)

    self.fid = "APPT-" \
               "#{start_time_in_pract_tz.strftime('%d-%m-%y-%H%M')}" \
               ":#{end_time_in_pract_tz.strftime('%H%M')}"
  end
end
