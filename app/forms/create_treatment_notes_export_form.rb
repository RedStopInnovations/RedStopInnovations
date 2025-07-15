class CreateTreatmentNotesExportForm < BaseForm
  attr_accessor :business

  attribute :start_date, String
  attribute :end_date, String

  attribute :template_ids, Array[Integer] # @TODO: validate

  attribute :status, String
  attribute :description, String

  validates_date :start_date, on_or_before: :end_date
  validates_date :end_date, on_or_after: :start_date

  validates :status, inclusion: { in: %w(Draft Final) },
            allow_nil: true, allow_blank: true

  validates :description, presence: true, length: {maximum: 300}

  validate do
    unless errors.key?(:start_date) || errors.key?(:end_date)
      start_date_d = start_date.to_date
      end_date_d = end_date.to_date
      if (end_date_d.year * 12 + end_date_d.month) - (start_date_d.year * 12 + start_date_d.month) > 12
        errors.add(:start_date, 'The date range must not exceed 12 months')
      end
    end
  end
end
