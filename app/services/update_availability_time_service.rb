class UpdateAvailabilityTimeService
  attr_reader :availability, :original_availability, :form_request

  # @param availability Availability
  # @param form UpdateAvailabilityTimeForm
  def call(availability, form_request)
    @availability = availability
    @original_availability = availability.dup
    @form_request = form_request

    availability.assign_attributes(@form_request.attributes.slice(
      :start_time, :end_time
    ))

    if availability_time_changed?
      availability.save!(validate: false)

      Availability.transaction do
        # Save availability changes
        availability.save!(validate: false)

        # Apply changes to its appointments
        Appointment.where(availability_id: availability.id).
          with_deleted.
          each do |appt|
            appt.update(
              start_time: availability.start_time,
              end_time: availability.end_time
            )
          end

        # Update appointment arrivals
        if availability.home_visit?
          HomeVisitRouting::ArrivalCalculate.new.call(availability.id)
        elsif availability.facility?
          HomeVisitRouting::FacilityArrivalCalculate.new.call(availability.id)
        elsif availability.group_appointment?
          HomeVisitRouting::GroupAppointmentArrivalCalculate.new.call(availability.id)
        end

        # Apply to repeat
        if apply_to_future_repeats? && availability.recurring?
          apply_for_repeats(availability)
        end

        AvailabilityCachedStats.new.update(availability)
      end

      # Sync changes to Google calendar
      if availability.practitioner&.user&.google_calendar_sync_setting&.status_active?
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
    end

    availability
  end

  private

  def availability_time_changed?
    (original_availability.start_time != availability.start_time) ||
      (original_availability.end_time != availability.end_time)
  end

  def apply_to_future_repeats?
    @form_request.apply_to_future_repeats
  end

  # def home_visit_availability?
  #   @original_availability.home_visit?
  # end

  # def facility_availability?
  #   @original_availability.facility?
  # end

  # def non_billable_availability?
  #   @original_availability.non_billable?
  # end

  # def group_appointment_availability?
  #   @original_availability.group_appointment?
  # end

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

    repeat_avails.each do |repeat_avail|
      repeat_avail.start_time = repeat_avail.start_time.change(
        hour: source_avail.start_time.strftime('%H'),
        min: source_avail.start_time.strftime('%M')
      )

      repeat_avail.end_time = repeat_avail.end_time.change(
        hour: source_avail.end_time.strftime('%H'),
        min: source_avail.end_time.strftime('%M')
      )

      if repeat_avail.start_time_changed? || repeat_avail.end_time_changed?
        Appointment.where(availability_id: repeat_avail.id).
          with_deleted.
          each do |appt|
            appt.update(
              start_time: repeat_avail.start_time,
              end_time: repeat_avail.end_time
            )
          end
      end

      repeat_avail.save!(validate: false)

      if repeat_avail.home_visit?
        HomeVisitRouting::ArrivalCalculate.new.call(repeat_avail.id)
      elsif repeat_avail.facility?
        HomeVisitRouting::FacilityArrivalCalculate.new.call(repeat_avail.id)
      elsif repeat_avail.group_appointment?
        HomeVisitRouting::GroupAppointmentArrivalCalculate.new.call(repeat_avail.id)
      end

      AvailabilityCachedStats.new.update(repeat_avail)
    end
  end
end
