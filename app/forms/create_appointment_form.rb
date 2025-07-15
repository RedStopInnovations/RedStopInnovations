class CreateAppointmentForm < BaseForm
  attribute :patient_id, Integer
  attribute :availability_id, Integer
  attribute :appointment_type_id, Integer
  attribute :break_times, Integer
  attribute :notes, String
  attribute :skip_service_area_restriction, Boolean, default: false

  validates_presence_of :availability_id, :patient_id, :appointment_type_id
  validates_length_of :notes, maximum: 300, allow_nil: true, allow_blank: true

  validates :break_times, numericality: { only_integer: true }, allow_blank: true, allow_nil: true

  def target_availability
    @target_availability ||= Availability.find_by(id: availability_id)
  end
end
