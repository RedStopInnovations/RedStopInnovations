class UpdateAvailabilityService
  attr_reader :availability, :original_availability, :form_request

  # @param availability Availability
  # @param form UpdateAvailabilityForm
  def call(availability, form_request)
    @availability = availability
    @original_availability = availability.dup
    @form_request = form_request

    availability.assign_attributes(availability_update_attrs)

    Availability.transaction do
      update_availability

      if apply_to_future_repeats? &&
        availability.recurring? &&
        (availability.home_visit? || availability.facility? || availability.non_billable?)
        apply_for_repeats(availability)
      end
    end

    if availability_time_changed?
      if availability.home_visit?
        HomeVisitRouting::ArrivalCalculate.new.call(availability.id)
      elsif availability.facility?
        HomeVisitRouting::FacilityArrivalCalculate.new.call(availability.id)
      elsif availability.group_appointment?
        HomeVisitRouting::GroupAppointmentArrivalCalculate.new.call(availability.id)
      end

      AvailabilityCachedStats.new.update(availability)
    end

    if availability.practitioner&.user&.google_calendar_sync_setting&.status_active? && needed_sync_to_google_calendar?
      SyncAvailabilityToGoogleCalendarWorker.perform_async(availability.id)

      if availability.recurring? && apply_to_future_repeats?
        Availability.where(
          recurring_id: availability.recurring_id,
          practitioner_id: availability.practitioner_id
        ).
          where('id <> ?', availability.id).
          where('start_time > ?', availability.start_time).
          pluck(:id).
          each do |repeat_avail_id|

          SyncAvailabilityToGoogleCalendarWorker.perform_async(repeat_avail_id)
        end
      end
    end

    availability
  end

  private

  def update_availability
    if home_visit_availability? || facility_availability? || group_appointment_availability?
      availability.geocode
    end

    availability.save!(validate: false)

    # Update start/end time for its appointments
    if availability_time_changed?
      Appointment.where(availability_id: availability.id).
        with_deleted.
        each do |appt|
          appt.update(
            start_time: availability.start_time,
            end_time: availability.end_time
          )
        end
    end
  end

  def availability_time_changed?
    (original_availability.start_time != availability.start_time) ||
      (original_availability.end_time != availability.end_time)
  end

  # Check whether the availability need to sync to google calendar or not
  def needed_sync_to_google_calendar?
    (availability.home_visit? || availability.non_billable? || availability.group_appointment?) &&
      %i(name contact_id description start_time end_time address1 city state postcode group_appointment_type_id).any? do |attr|
        original_availability[attr] != availability[attr]
      end
  end

  def apply_to_future_repeats?
    @form_request.apply_to_future_repeats
  end

  def home_visit_availability?
    @original_availability.home_visit?
  end

  def facility_availability?
    @original_availability.facility?
  end

  def non_billable_availability?
    @original_availability.non_billable?
  end

  def group_appointment_availability?
    @original_availability.group_appointment?
  end

  def availability_update_attrs
    massive_attributes = %i[
      start_time end_time
    ]

    if home_visit_availability?
      massive_attributes.concat %i[
        service_radius max_appointment address1 city state postcode country allow_online_bookings
      ]
    elsif facility_availability?
      massive_attributes.concat %i[
        contact_id max_appointment address1 city state postcode country allow_online_bookings
      ]
    elsif non_billable_availability?
      massive_attributes.concat %i[
        contact_id address1 city state postcode country name description availability_subtype_id
      ]
    end

    @form_request.attributes.slice *massive_attributes
  end

  def apply_for_repeats(source_avail)
    business = source_avail.business
    repeat_avails = business.availabilities.
      where('recurring_id IS NOT NULL').
      where(
        recurring_id: source_avail.recurring_id,
        practitioner_id: source_avail.practitioner_id
      ).
      where('id <> ?', source_avail.id).
      where('start_time > ?', source_avail.start_time)

    repeat_avails.each do |avail|
      avail.assign_attributes(
        source_avail.attributes.symbolize_keys.slice(
          :name,
          :description,
          :service_radius,
          :max_appointment,
          :availability_subtype_id,
          :address1,
          :city,
          :state,
          :postcode,
          :country,
          :allow_online_bookings,
          :contact_id
        )
      )
      avail.start_time = avail.start_time.change(
        hour: source_avail.start_time.strftime('%H'),
        min: source_avail.start_time.strftime('%M')
      )

      avail.end_time = avail.end_time.change(
        hour: source_avail.end_time.strftime('%H'),
        min: source_avail.end_time.strftime('%M')
      )

      if source_avail.latitude? && source_avail.longitude?
        avail.latitude  = source_avail.latitude
        avail.longitude = source_avail.longitude
      end

      is_availability_time_change = avail.start_time_changed? || avail.end_time_changed?

      if is_availability_time_change
        Appointment.where(availability_id: avail.id).
          with_deleted.
          update_all(
            start_time: avail.start_time,
            end_time: avail.end_time
          )
      end

      # FIXME: N+1 query here
      avail.save!(validate: false)

      if is_availability_time_change
        if avail.home_visit?
          HomeVisitRouting::ArrivalCalculate.new.call(avail.id)
        elsif avail.facility?
          HomeVisitRouting::FacilityArrivalCalculate.new.call(avail.id)
        elsif avail.group_appointment?
          HomeVisitRouting::GroupAppointmentArrivalCalculate.new.call(avail.id)
        end

        AvailabilityCachedStats.new.update(avail)
      end
    end
  end
end
