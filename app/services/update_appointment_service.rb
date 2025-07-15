class UpdateAppointmentService
  class Error < StandardError; end

  attr_reader :business, :appointment, :form_request, :availability,
              :original_appointment

  # @param appointment Appointment
  # @param form_request UpdateAppointmentForm
  def call(business, appointment, form_request)
    @original_appointment = appointment.dup
    @appointment = appointment
    @business = business
    @form_request = form_request

    @availability = business.availabilities.find form_request.availability_id
    patient = appointment.patient
    appt_type = business.appointment_types.find(form_request.appointment_type_id)

    # if (availability.availability_type_id == AvailabilityType::TYPE_HOME_VISIT_ID) &&
    #    !form_request.skip_service_area_restriction
    #   ensure_availability_service_radius(availability, patient)
    # end

    ActiveRecord::Base.transaction do
      update_appointment
      if availability_changed? && (@availability.home_visit? || @availability.facility?)
        @availability.reload.refresh_appointments_order
        Availability.find(original_appointment.availability_id).refresh_appointments_order
      end

      if @availability.home_visit?
        HomeVisitRouting::ArrivalCalculate.new.call(@availability.id)
        # TODO: maybe more this to background job
        HomeVisitRouting::ArrivalCalculate.new.call(original_appointment.availability_id)
      elsif @availability.facility?
        HomeVisitRouting::FacilityArrivalCalculate.new.call(@availability.id)
      end

      AvailabilityCachedStats.new.update(@availability)
    end

    if appointment_time_changed? && appointment.start_time.future?
      # Notify practitioner the update
      SendAppointmentNotificationJob.perform_later(appointment.id, NotificationType::APPOINTMENT__UPDATED)

      if patient.reminder_enable? && appt_type.reminder_enable?
        # Client notifications
        if (business.communication_template_enabled?('appointment_reminder') || business.communication_template_enabled?('appointment_reminder_sms'))
          _24h_reminder_at = appointment.start_time - 1.day
          if _24h_reminder_at.future?
            AppointmentReminderWorker.perform_at(_24h_reminder_at, appointment.id)
          end
        end

        if business.communication_template_enabled?('appointment_reminder_sms_1week')
          _1week_reminder_at = appointment.start_time - 7.days
          if _1week_reminder_at.future?
            AppointmentReminderWeekWorker.perform_at(_1week_reminder_at, appointment.id)
          end
        end
      end
    end

    if appointment.home_visit?
      if @availability.practitioner&.user&.google_calendar_sync_setting&.status_active?
        SyncAvailabilityToGoogleCalendarWorker.perform_async(@availability.id)
      end

      # TODO: what if practitioner has changed?
      if availability_changed?
        SyncAvailabilityToGoogleCalendarWorker.perform_async(original_appointment.availability_id)
      end
    end

    appointment
  end

  private

  def appointment_type_changed?
    appointment.appointment_type_id != original_appointment.appointment_type_id
  end

  def appointment_time_changed?
    appointment.start_time != original_appointment.start_time
  end

  def availability_changed?
    appointment.availability_id != original_appointment.availability_id
  end

  def update_appointment
    appointment.assign_attributes(
      @form_request.attributes.slice(
      *%i(availability_id notes patient_case_id)
      )
    )

    appointment.practitioner_id = availability.practitioner_id

    if availability.home_visit? || @availability.facility?
      appointment.assign_attributes(
        @form_request.attributes.slice(
        *%i(appointment_type_id break_times)
        )
      )
    end

    if availability_changed?
      appointment.assign_attributes(
        start_time: availability.start_time,
        end_time: availability.end_time
      )
    end

    if availability.group_appointment?
      if availability_changed?
        appointment.appointment_type_id = availability.group_appointment_type&.id
      end

      arrival = appointment.arrival || appointment.build_arrival

      if arrival.persisted? && arrival.arrival_at != availability.start_time
        arrival.sent_at = nil
      end

      arrival.arrival_at = availability.start_time
      arrival.travel_distance = 0
      arrival.travel_duration = 0

      arrival.save!
    end

    appointment.save!(validate: false)
  end

  # def ensure_availability_service_radius(avail, patient)
  #   # NOTE: allow all patient if avaibility location info is not present
  #   # Might we need to raise an error
  #   if avail.service_radius? && avail.latitude? && avail.longitude?
  #     if patient.latitude? && patient.longitude?
  #       distance = Geocoder::Calculations.distance_between(
  #         [patient.latitude, patient.longitude],
  #         [avail.latitude, avail.longitude]
  #       ).round
  #     else
  #       raise Error, 'Patient location is not recognized.'
  #     end
  #   else
  #     distance = 0
  #   end

  #   if distance > avail.service_radius
  #     raise Error, 'Patient location is out of service radius.'
  #   end
  # end
end
