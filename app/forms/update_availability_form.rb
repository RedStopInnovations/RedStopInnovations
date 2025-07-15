class UpdateAvailabilityForm < BaseForm
  attr_accessor :business

  attribute :availability_id, Integer
  attribute :service_radius, Integer
  attribute :max_appointment, Integer
  attribute :start_time, String
  attribute :end_time, String
  attribute :address1, String
  attribute :address2, String
  attribute :city, String
  attribute :state, String
  attribute :postcode, String
  attribute :country, String
  attribute :repeat, Boolean, default: false
  attribute :allow_online_bookings, Boolean, default: true
  attribute :apply_to_future_repeats, Boolean, default: false
  attribute :contact_id, Integer
  attribute :name, String
  attribute :description, String
  attribute :availability_subtype_id, Integer

  validates_presence_of :availability_id, :start_time, :end_time
  validates_datetime :start_time
  validates_datetime :end_time, after: :start_time

  validates_numericality_of :max_appointment,
                            :service_radius,
                            only_integer: true,
                            greater_than: 0,
                            allow_nil: true,
                            allow_blank: true

  validates_presence_of :max_appointment,
                        :service_radius,
                        :address1,
                        :city,
                        :state,
                        :country,
                        if: :home_visit_availability?

  validates_presence_of :contact_id, if: :facility_availability?

  validates :name,
            presence: true,
            length: { maximum: 200 },
            if: :non_billable_availability?

  validates :description,
            length: { maximum: 200 },
            allow_nil: true,
            allow_blank: true,
            if: :non_billable_availability?

  validates :availability_subtype_id,
            inclusion: {in: lambda { |m| m.business.availability_subtypes.pluck(:id) }},
            allow_nil: true,
            allow_blank: true,
            if: :non_billable_availability?

  validate do
    unless errors.key?(:contact_id)
      if contact_id.present? && !business.contacts.where(id: contact_id).exists?
        errors.add(:contact_id, 'is not existing')
      end
    end
  end

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

  def facility_availability?
    availability.facility?
  end

  def home_visit_availability?
    availability.home_visit?
  end

  def non_billable_availability?
    availability.non_billable?
  end
end
