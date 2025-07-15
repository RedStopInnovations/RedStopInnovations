class SendPatientMessageForm < BaseForm
  attr_accessor :business

  attribute :patient_id, Integer
  attribute :content, String
  attribute :communication_category, String
  attribute :source_id, Integer
  attribute :source_type, String

  validates :patient_id, presence: true

  validates :content,
            presence: true,
            length: { min: 10, maximum: 500 }

  validates :communication_category,
            inclusion: { in: Communication::CATEGORIES },
            allow_nil: true,
            allow_blank: true

  validates :source_type,
            inclusion: { in: [::Appointment.name, ::Invoice.name] },
            allow_nil: true,
            allow_blank: true

  validate do
    if patient_id.present? && !business.patients.where(id: patient_id).exists?
      errors.add(:patient_id, 'does not exist')
    end
  end

  validate do
    if source_type.present? && !errors.key?(:source_type) && !errors.key?(:patient_id)
      if !source_id.present?
        errors.add(:source_id, 'source_id must be specified')
      else
        case source_type
        when ::Appointment.name
          if !Appointment.where(patient_id: patient_id, id: source_id).exists?
            errors.add(:source_id, 'source_id does not exist')
          end
        when ::Invoice.name
          if !Invoice.where(patient_id: patient_id, id: source_id).exists?
            errors.add(:source_id, 'source_id does not exist')
          end
        end
      end
    end
  end
end
