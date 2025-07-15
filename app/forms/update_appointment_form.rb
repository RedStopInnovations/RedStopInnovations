class UpdateAppointmentForm < BaseForm
  attribute :id, Integer
  attribute :availability_id, Integer
  attribute :appointment_type_id, Integer
  attribute :patient_case_id, Integer
  attribute :break_times, Integer
  attribute :notes, String
  attribute :skip_service_area_restriction, Boolean, default: false

  validates_presence_of :availability_id, :appointment_type_id
  validates_length_of :notes, maximum: 300, allow_nil: true, allow_blank: true

  validates :break_times, numericality: { only_integer: true }, allow_blank: true, allow_nil: true

  def original_appointment
    @original_appointment ||= Appointment.find(id)
  end

  def target_availability
    @target_availability ||= Availability.find_by(id: availability_id)
  end

  validate do
    business = original_appointment.business

    if patient_case_id.present?
      if !PatientCase.where(id: patient_case_id, patient_id: original_appointment.patient_id).exists?
        errors.add(:patient_case_id, 'is not existing')
      end
    end

    unless errors.key?(:appointment_type_id) || business.appointment_types.exists?(id: appointment_type_id)
      errors.add(:appointment_type_id, 'is not existing')
    end

    unless errors.key?(:availability_id) || business.availabilities.exists?(id: availability_id)
      errors.add(:availability_id, 'is not existing')
    end
  end
end
