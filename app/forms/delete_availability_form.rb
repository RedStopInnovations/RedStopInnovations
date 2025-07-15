class DeleteAvailabilityForm < BaseForm
  attr_accessor :availability

  attribute :delete_future_repeats, Boolean, default: false
  attribute :notify_cancel_appointment, Boolean, default: true

  validate do
    if availability.appointments.count > 1
      errors.add(:base, "Not allowed to delete availability that has more than one appointment. Need to cancel or delete some appointments first.")
    end
  end
end
