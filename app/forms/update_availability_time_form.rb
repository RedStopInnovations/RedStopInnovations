class UpdateAvailabilityTimeForm < BaseForm
  attr_accessor :availability

  attribute :start_time, String
  attribute :end_time, String
  attribute :apply_to_future_repeats, Boolean, default: false

  validates_presence_of :start_time, :end_time
  validates_datetime :start_time
  validates_datetime :end_time, after: :start_time
end
