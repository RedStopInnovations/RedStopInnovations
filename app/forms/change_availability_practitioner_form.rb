class ChangeAvailabilityPractitionerForm < BaseForm
  attr_accessor :business, :availability
  attribute :practitioner_id, Integer
  attribute :apply_to_future_repeats, Boolean, default: false

  validates_presence_of :practitioner_id

  validate do
    if availability.start_time.past?
      errors.add(:base, 'Cannot change practitioner for an availability in the past.')
    end
  end

  validate do
    unless errors.key?(:practitioner_id)
      if !business.practitioners.where(id: practitioner_id).exists?
        errors.add(:practitioner_id, 'is not found.')
      end
    end

    unless errors.key?(:practitioner_id)
      if availability.practitioner_id == practitioner_id
        errors.add(:practitioner_id, 'cannot be the same current practitioner.')
      end
    end
  end
end
