class CreateGroupAppointmentAvailabilityForm < BaseForm
  attr_accessor :business

  attribute :practitioner_id, Integer
  attribute :start_time, String
  attribute :end_time, String
  attribute :max_appointment, Integer

  attribute :address1, String
  attribute :address2, String
  attribute :city, String
  attribute :state, String
  attribute :postcode, String
  attribute :country, String

  attribute :description, String
  attribute :contact_id, Integer
  attribute :appointment_type_id, Integer

  validates_presence_of :start_time, :end_time
  validates_presence_of :practitioner_id, :appointment_type_id, :max_appointment

  validates_datetime :start_time
  validates_datetime :end_time, after: :start_time

  validates :description,
            length: { maximum: 200 },
            allow_nil: true,
            allow_blank: true

  validates_presence_of :address1,
                        :city,
                        :state,
                        :country

  validates_numericality_of :max_appointment,
                            only_integer: true,
                            greater_than: 0,
                            allow_nil: true,
                            allow_blank: true

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

    unless errors.key?(:appointment_type_id)
      appt_type = business.appointment_types.find_by(id: appointment_type_id)

      if appt_type.nil?
        errors.add(:appointment_type_id, 'is not existing')
      elsif !appt_type.group_appointment?
        errors.add(:appointment_type_id, 'is not a group appointment type')
      end
    end
  end
end
