class UpdateGroupAppointmentAvailabilityForm < BaseForm
  attr_accessor :business

  attribute :availability_id, Integer
  attribute :max_appointment, Integer
  attribute :start_time, String
  attribute :end_time, String

  attribute :address1, String
  attribute :address2, String
  attribute :city, String
  attribute :state, String
  attribute :postcode, String
  attribute :country, String

  attribute :description, String
  attribute :contact_id, Integer
  attribute :group_appointment_type_id, Integer

  validates_presence_of :availability_id, :start_time, :end_time
  validates_datetime :start_time
  validates_datetime :end_time, after: :start_time

  validates_numericality_of :max_appointment,
                            only_integer: true,
                            greater_than: 0,
                            allow_nil: true,
                            allow_blank: true

  validates_presence_of :group_appointment_type_id,
                        :max_appointment,
                        :address1,
                        :city,
                        :state,
                        :country

  validates :description,
            length: { maximum: 200 },
            allow_nil: true,
            allow_blank: true

  def availability
    @availability ||= business.availabilities.find_by(id: availability_id)
  end

  def availability_time_changed?
    (parsed_start_time != availability.start_time) ||
      (parsed_end_time != availability.end_time)
  end

  def parsed_start_time
    @parsed_start_time ||= Time.zone.parse(start_time)
  end

  def parsed_end_time
    @parsed_end_time ||= Time.zone.parse(end_time)
  end

  validate do
    unless errors.key?(:contact_id)
      if contact_id.present? && !business.contacts.where(id: contact_id).exists?
        errors.add(:contact_id, 'is not existing')
      end
    end

    unless errors.key?(:group_appointment_type_id)
      appt_type = business.appointment_types.find_by(id: group_appointment_type_id)

      if appt_type.nil?
        errors.add(:group_appointment_type_id, 'is not existing')
      elsif !appt_type.group_appointment?
        errors.add(:group_appointment_type_id, 'is not a group appointment type')
      end
    end
  end

end
