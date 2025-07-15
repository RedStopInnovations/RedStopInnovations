class CreateAvailabilityForm < BaseForm
  include Common::AddressLengthValidations

  attr_accessor :business
  attribute :practitioner_id, Integer
  attribute :service_radius, Integer
  attribute :max_appointment, Integer
  attribute :start_time, String
  attribute :end_time, String
  attribute :address1, String
  attribute :address2, String
  attribute :city, String
  attribute :state, String
  attribute :postcode, String
  attribute :country, String
  attribute :contact_ids, Array
  attribute :allow_online_bookings, Boolean, default: true
  attribute :availability_type_id, Integer
  attribute :contact_id, Integer
  attribute :repeat_type, String
  attribute :repeat_interval, Integer, default: 1
  attribute :repeat_total, Integer

  validates_presence_of :practitioner_id
  validates_numericality_of :max_appointment,
                            :service_radius,
                            only_integer: true,
                            greater_than: 0,
                            allow_nil: true,
                            allow_blank: true

  validates_presence_of :start_time, :end_time

  validates_datetime :start_time
  validates_datetime :end_time, after: :start_time
  validates :availability_type_id,
            presence: true,
            inclusion: {
              in: [
                AvailabilityType::TYPE_HOME_VISIT_ID, AvailabilityType::TYPE_FACILITY_ID
              ],
              message: 'is not a valid availability type'
            }

  validates_presence_of :max_appointment,
                        :service_radius,
                        :address1,
                        :city,
                        :state,
                        :country,
                        if: :home_visit_availability?

  validates_presence_of :contact_id, if: :facility_availability?
  validates :repeat_type,
            inclusion: {
              in: %w(daily weekly monthly)
            },
            allow_blank: true,
            allow_nil: true

  validates :repeat_interval,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than: 10
            },
            allow_nil: true,
            allow_blank: true,
            if: :repeat?

  validates :repeat_total,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than: 100
            },
            allow_nil: true,
            allow_blank: true,
            if: :repeat?

  validates_presence_of :repeat_interval, :repeat_total,
                        if: :repeat?

  validate do
    unless errors.key?(:practitioner_id)
      if !business.practitioners.where(id: practitioner_id).exists?
        errors.add(:practitioner_id, 'is not found.')
      end
    end
  end

  def home_visit_availability?
    availability_type_id == AvailabilityType::TYPE_HOME_VISIT_ID
  end

  def facility_availability?
    availability_type_id == AvailabilityType::TYPE_FACILITY_ID
  end

  validate if: :facility_availability? do
    unless errors.key?(:contact_id)
      unless business.contacts.where(id: contact_id).exists?
        errors.add(:contact_id, 'is not existing')
      end
    end
  end

  def repeat?
    repeat_type.present?
  end
end
