class PatientBulkArchiveRequestForm < BaseForm
  attr_accessor :business

  attribute :create_date_from, String
  attribute :create_date_to, String
  attribute :contact_id, Integer
  attribute :no_appointment_period, String
  attribute :no_invoice_period, String
  attribute :no_treatment_note_period, String
  attribute :description, String

  validates_date :create_date_from, on_or_before: :create_date_to, allow_nil: true, allow_blank: true
  validates_date :create_date_to, on_or_after: :create_date_from, allow_nil: true, allow_blank: true

  validates :no_appointment_period, :no_invoice_period, :no_treatment_note_period,
            inclusion: { in: %w(ALL 6m 9m 1y 2y 3y) },
            allow_nil: true,
            allow_blank: true

  validates :description, length: {maximum: 300}, allow_nil: true, allow_blank: true

  validate do
    if contact_id.present? && !business.contacts.with_deleted.where(id: contact_id).exists?
      errors.add :contact_id, 'does not exist'
    end
  end

  validate do
    # At least one filter
    if !create_date_from.present? &&
      !create_date_to.present? &&
      !contact_id.present? &&
      !no_appointment_period.present? &&
      !no_invoice_period.present? &&
      !no_treatment_note_period.present?

      errors.add :base, 'Must specific at least one criteria'
    end
  end
end