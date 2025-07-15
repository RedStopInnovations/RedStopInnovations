class CreateCompleteTaskForm < BaseForm
  attr_accessor :business

  attribute :patient_id, Integer
  attribute :name, String
  attribute :description, String
  attribute :complete_at, String
  attribute :completion_duration, Integer
  attribute :is_invoice_required, Boolean

  validates_presence_of :name, :complete_at

  validates :name,
            presence: true,
            length: { minimum: 3, maximum: 250 }

  validates :description,
            length: { maximum: 1000 }

  validates :completion_duration,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 480
            },
            allow_nil: true,
            allow_blank: true

  validates_datetime :complete_at

  validate do
    if !errors.key?(:patient_id) && patient_id.present?
      if !business.patients.exists?(id: patient_id)
        errors.add(:base, 'Client is not valid')
      end
    end
  end
end