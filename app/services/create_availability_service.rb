class CreateAvailabilityService
  REPEAT_TYPE_DAILY = 'daily'
  REPEAT_TYPE_WEEKLY = 'weekly'
  REPEAT_TYPE_MONTHLY = 'monthly'

  attr_reader :business, :form_request

  # @param business Business
  # @param form CreateAvailabilityForm
  def call(business, form_request)
    @business = business
    @form_request = form_request

    avail = build_availability
    if repeat? && (avail.home_visit? || avail.facility?)
      avail_recurring = create_availability_recurring(avail)
      avail.recurring_id = avail_recurring.id
    end

    Availability.transaction do
      avail.save!(validate: false)

      if repeat? && (avail.home_visit? || avail.facility?)
        create_repeats(avail)
      end

      AvailabilityCachedStats.new.update(avail)
    end

    avail
  end

  private

  def repeat?
    form_request.repeat_type.present?
  end

  def home_visit_availability?
    form_request.home_visit_availability?
  end

  def facility_availability?
    form_request.facility_availability?
  end

  def build_availability
    avail = Availability.new(business_id: business.id)
    avail.availability_type_id = form_request.availability_type_id

    case form_request.availability_type_id
    when AvailabilityType::TYPE_HOME_VISIT_ID
      avail.assign_attributes home_visit_availability_attrs
    when AvailabilityType::TYPE_FACILITY_ID
      avail.assign_attributes facility_availability_attrs
    end

    avail
  end

  def create_availability_recurring(source_avail)
    AvailabilityRecurring.create!(
      practitioner_id: source_avail.practitioner_id,
      repeat_type: form_request.repeat_type,
      repeat_total: form_request.repeat_total,
      repeat_interval: form_request.repeat_interval
    )
  end

  def home_visit_availability_attrs
    form_request.attributes.slice(
      :practitioner_id,
      :start_time,
      :end_time,
      :service_radius,
      :max_appointment,
      :address1,
      :city,
      :state,
      :postcode,
      :country,
      :allow_online_bookings
    )
  end

  def facility_availability_attrs
    form_request.attributes.slice(
      :practitioner_id,
      :start_time,
      :end_time,
      :contact_id,
      :address1,
      :city,
      :state,
      :postcode,
      :country,
      :max_appointment
    ).merge(
      allow_online_bookings: false
    )
  end

  def create_repeats(source_avail)
    last_repeat = source_avail

    form_request.repeat_total.times do |time|
      repeat_avail = Availability.new(
        source_avail.attributes.symbolize_keys.slice(
          :practitioner_id,
          :availability_type_id,
          :service_radius,
          :max_appointment,
          :address1,
          :city,
          :state,
          :postcode,
          :country,
          :allow_online_bookings,
          :contact_id
        )
      )

      repeat_avail.business_id = business.id
      repeat_avail.start_time, repeat_avail.end_time =
        case form_request.repeat_type
        when REPEAT_TYPE_DAILY
          [
            last_repeat.start_time.advance(days: form_request.repeat_interval),
            last_repeat.end_time.advance(days: form_request.repeat_interval)
          ]
        when REPEAT_TYPE_WEEKLY
          [
            last_repeat.start_time.advance(weeks: form_request.repeat_interval),
            last_repeat.end_time.advance(weeks: form_request.repeat_interval)
          ]
        when REPEAT_TYPE_MONTHLY
          [
            last_repeat.start_time.advance(months: form_request.repeat_interval),
            last_repeat.end_time.advance(months: form_request.repeat_interval)
          ]
        else
          raise "Uknown repeat type: #{form_request.repeat_type}"
        end

      if source_avail.latitude? && source_avail.longitude?
        repeat_avail.latitude     = source_avail.latitude
        repeat_avail.longitude    = source_avail.longitude
      end
      repeat_avail.recurring_id = source_avail.recurring_id
      repeat_avail.save!(validate: false)

      AvailabilityCachedStats.new.update(repeat_avail)

      last_repeat = repeat_avail
    end
  end
end
