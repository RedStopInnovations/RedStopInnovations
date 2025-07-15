class UpdateWaitListForm < BaseForm
  attr_accessor :business

  attribute :patient_id, Integer
  attribute :appointment_type_id, Integer
  attribute :practitioner_id, Integer
  attribute :profession, String
  attribute :date, String
  attribute :apply_to_repeats, Boolean, default: false
  attribute :notes, String

  validates :patient_id, presence: true

  validates :date, presence: true

  validates :profession, presence: true

  validates :profession,
            inclusion: { in: Practitioner::PROFESSIONS },
            allow_blank: true

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
