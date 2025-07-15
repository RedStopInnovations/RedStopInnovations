class CreateWaitListForm < BaseForm
  attr_accessor :business

  attribute :patient_id, Integer
  attribute :appointment_type_id, Integer
  attribute :practitioner_id, Integer
  attribute :profession, String
  attribute :date, String
  attribute :repeat_type, String
  attribute :repeat_frequency, Integer
  attribute :repeats_total, Integer
  attribute :notes, String

  validates :patient_id, presence: true

  validates :date, presence: true

  validates :profession, presence: true

  validates :profession,
            inclusion: { in: Practitioner::PROFESSIONS },
            allow_blank: true

  validates :repeat_type,
            inclusion: { in: %w(Daily Weekly) },
            allow_nil: true,
            allow_blank: true

  validates :repeat_frequency, :repeats_total,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 20
            },
            if: Proc.new { repeat_type.present? }

  validates_length_of :notes, maximum: 1000

  validate do
    if !errors.key?(:practitioner_id) &&
       practitioner_id.present? &&
       !business.practitioners.exists?(id: practitioner_id)
      errors.add(:practitioner_id, 'is not existing.')
    end

    if !errors.key?(:appointment_type_id) &&
       appointment_type_id.present? &&
       !business.appointment_types.exists?(id: appointment_type_id)
      errors.add(:appointment_type_id, 'is not existing.')
    end

    if !errors.key?(:patient_id) &&
       patient_id.present? &&
       !business.patients.exists?(id: patient_id)
      errors.add(:patient_id, 'is not existing.')
    end
  end
end
