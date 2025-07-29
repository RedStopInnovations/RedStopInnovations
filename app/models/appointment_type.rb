# == Schema Information
#
# Table name: appointment_types
#
#  id                            :integer          not null, primary key
#  business_id                   :integer          not null
#  name                          :string
#  description                   :text
#  item_number                   :string
#  duration                      :integer
#  price                         :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  reminder_enable               :boolean          default(TRUE)
#  default_billable_item_id      :integer
#  default_treatment_template_id :integer
#  availability_type_id          :integer
#  deleted_at                    :datetime
#  display_on_online_bookings    :boolean          default(TRUE)
#  color                         :string
#
# Indexes
#
#  index_appointment_types_on_business_id                           (business_id)
#  index_appointment_types_on_business_id_and_availability_type_id  (business_id,availability_type_id)
#

class AppointmentType < ApplicationRecord
  include DeletionRecordable

  belongs_to :business, inverse_of: :appointment_types
  # belongs_to :default_billable_item, class_name: 'BillableItem' # TODO: remove after issue #2287 is done
  belongs_to :default_treatment_template, class_name: 'TreatmentTemplate'
  has_many :appointments
  has_and_belongs_to_many :practitioners, validate: false # TODO: validate business scope?
  has_and_belongs_to_many :billable_items, validate: false, uniq: true # TODO: validate business scope?

  validates_presence_of :name
  validates_length_of :name, maximum: 255, allow_nil: true, allow_blank: true
  validates :duration,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 600
            }

  validates :availability_type_id,
            presence: true,
            inclusion: {
              in: AvailabilityType::TYPE_IDS,
              message: 'is not a valid availability type'
            }
  validates_length_of :description, maximum: 1000

  scope :home_visit,
        -> { where(availability_type_id: AvailabilityType::TYPE_HOME_VISIT_ID) }
  scope :telehealth,
        -> { where(availability_type_id: AvailabilityType::TYPE_TELEHEALTH_ID) }
  scope :facility,
        -> { where(availability_type_id: AvailabilityType::TYPE_FACILITY_ID) }
  scope :not_deleted, -> { where(deleted_at: nil) }

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

  def group_appointment?
    availability_type_id == AvailabilityType::TYPE_GROUP_APPOINTMENT_ID
  end

  def deleted?
    deleted_at?
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      'name', 'availability_type_id'
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
