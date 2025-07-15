class SingleHomeVisitAvailabilityForm < BaseForm
  attr_accessor :business

  attribute :start_time, String
  attribute :end_time, String
  attribute :address1, String
  attribute :address2, String
  attribute :city, String
  attribute :state, String
  attribute :postcode, String
  attribute :country, String

  attribute :practitioner_id, Integer
  attribute :patient_id, Integer
  attribute :appointment_type_id, Integer
  attribute :patient_case_id, Integer

  attribute :repeat_type, String
  attribute :repeat_interval, Integer, default: 1
  attribute :repeat_total, Integer

  validates_presence_of :start_time, :end_time
  validates_presence_of :practitioner_id, :patient_id, :appointment_type_id

  validates_datetime :start_time
  validates_datetime :end_time, after: :start_time

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

  validates_presence_of :repeat_interval, :repeat_total, if: :repeat?

  validate do
    unless errors.key?(:patient_id)
      unless business.patients.where(id: patient_id).exists?
        errors.add(:patient_id, 'is not existing')
      end
    end

    if !errors.key?(:patient_id) && patient_case_id.present?
      unless PatientCase.where(id: patient_case_id, patient_id: patient_id).exists?
        errors.add(:patient_case_id, 'is not existing')
      end
    end

    unless errors.key?(:practitioner_id)
      unless business.practitioners.where(id: practitioner_id).exists?
        errors.add(:practitioner_id, 'is not existing')
      end
    end

    unless errors.key?(:appointment_type_id)
      appt_type = business.appointment_types.find_by(id: appointment_type_id)
      if appt_type.nil?
        errors.add(:appointment_type_id, 'is not existing')
      elsif !appt_type.home_visit?
        errors.add(:appointment_type_id, 'is not a home visit appointment type')
      end
    end
  end

  def repeat?
    repeat_type.present?
  end
end
