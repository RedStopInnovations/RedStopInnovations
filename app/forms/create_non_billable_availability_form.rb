class CreateNonBillableAvailabilityForm < BaseForm
  attr_accessor :business

  attribute :name, String
  attribute :description, String
  attribute :contact_id, Integer

  attribute :start_time, String
  attribute :end_time, String
  attribute :address1, String
  attribute :address2, String
  attribute :city, String
  attribute :state, String
  attribute :postcode, String
  attribute :country, String

  attribute :availability_subtype_id, Integer

  attribute :repeat_type, String
  attribute :repeat_interval, Integer, default: 1
  attribute :repeat_total, Integer

  attribute :practitioner_id, Integer

  validates_presence_of :start_time, :end_time
  validates_presence_of :practitioner_id

  validates_datetime :start_time
  validates_datetime :end_time, after: :start_time

  validates :name,
            presence: true,
            length: { maximum: 200 }

  validates :description,
            length: { maximum: 200 },
            allow_nil: true,
            allow_blank: true

  validates :availability_subtype_id,
            inclusion: {in: lambda { |m| m.business.availability_subtypes.pluck(:id) }},
            allow_nil: true,
            allow_blank: true

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
      unless business.practitioners.where(id: practitioner_id).exists?
        errors.add(:practitioner_id, 'is not existing')
      end
    end

    unless errors.key?(:contact_id)
      if contact_id.present? && !business.contacts.where(id: contact_id).exists?
        errors.add(:contact_id, 'is not existing')
      end
    end
  end

  def repeat?
    repeat_type.present?
  end
end
