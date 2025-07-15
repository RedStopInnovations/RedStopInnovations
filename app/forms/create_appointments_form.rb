class CreateAppointmentsForm < BaseForm
  attr_accessor :business

  attribute :patient_id, Integer
  attribute :availability_ids, Array[Integer]
  attribute :appointment_type_id, Integer
  attribute :patient_case_id, Integer
  attribute :notes, String

  validates_presence_of :availability_ids, :patient_id, :appointment_type_id

  validates :notes,
             length: { maximum: 300 },
             allow_nil: true,
             allow_blank: true

  validate do
    unless errors.key?(:patient_id) || business.patients.with_deleted.exists?(id: patient_id)
      errors.add(:patient_id, 'is not existing')
    end

    if patient_case_id.present? && patient_id.present?
      if !PatientCase.where(id: patient_case_id, patient_id: patient_id).exists?
        errors.add(:patient_case_id, 'is not existing')
      end
    end

    unless errors.key?(:appointment_type_id) ||
      business.appointment_types.exists?(id: appointment_type_id)
      errors.add(:appointment_type_id, 'is not existing')
    end

    unless errors.key?(:availability_ids) || errors.key?(:appointment_type_id)
      if availability_ids.uniq.size != business.availabilities.where(id: availability_ids).count
        errors.add(:availability_ids, 'some record are not existing')
      end

      # Availability must be match appointment type
      unless errors.key?(:availability_ids)
        appointment_type = business.appointment_types.find(appointment_type_id)
        if business.availabilities.where(id: availability_ids).pluck(:availability_type_id).uniq != [appointment_type.availability_type_id]
          errors.add(:availability_ids, 'some availability is not match the appointment type')
        end
      end
    end
  end
end
