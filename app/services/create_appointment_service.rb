# TODO: seem to be no longer used
class CreateAppointmentService
  class Error < StandardError; end
  # @param business Business
  # @param appointment_form CreateAppointmentForm
  def call(business, appointment_form)
    @business = business
    @appointment_form = appointment_form

    avail = business.availabilities.find appointment_form.availability_id
    practitioner = avail.practitioner
    patient = business.patients.find appointment_form.patient_id
    appt_type = business.appointment_types.find(appointment_form.appointment_type_id)

    if avail.home_visit? && !appointment_form.skip_service_area_restriction
      ensure_availability_service_radius(avail, patient)
    end

    appointment = nil

    ActiveRecord::Base.transaction do
      appointment = create_appointment(avail)

      if avail.home_visit?
        HomeVisitRouting::ArrivalCalculate.new.call(avail.id)
      elsif avail.facility?
        HomeVisitRouting::FacilityArrivalCalculate.new.call(avail.id)
      end

      AvailabilityCachedStats.new.update avail
    end

    if appointment
      if appointment.start_time.future?
        # Practitioner notifications
        SendAppointmentNotificationJob.perform_later(appointment.id, NotificationType::APPOINTMENT__CREATED)

        if patient.reminder_enable? && appointment.appointment_type.reminder_enable?
          if patient.email? && business.communication_template_enabled?('appointment_confirmation')
            AppointmentMailer.booking_confirmation(appointment.id).deliver_later
          end

          if business.communication_template_enabled?('appointment_reminder') || business.communication_template_enabled?('appointment_reminder_sms')
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

      # Grant patient access to practitioner
      PatientAccess.
        where(user_id: practitioner.user_id, patient_id: patient.id).
        first_or_create

      Webhook::Worker.perform_later(
        appointment.id,
        'appointment_created'
      )

      if appointment.home_visit? && practitioner&.user&.google_calendar_sync_setting&.status_active?
        SyncAvailabilityToGoogleCalendarWorker.perform_async(appointment.availability_id)
      end
    end

    appointment
  end

  private

  def create_appointment(avail)
    appt = Appointment.new(@appointment_form.attributes.slice(
      :patient_id, :appointment_type_id, :notes, :break_times
    ))
    if avail.home_visit? || avail.facility?
      appt.order = avail.appointments.maximum(:order).to_i + 1
    end
    appt.assign_attributes(
      availability_id: avail.id,
      practitioner_id: avail.practitioner_id
    )

    case avail.availability_type_id
    when AvailabilityType::TYPE_HOME_VISIT_ID
      appt.assign_attributes(
        start_time: avail.start_time,
        end_time: avail.end_time
      )
    when AvailabilityType::TYPE_FACILITY_ID
      appt.assign_attributes(
        start_time: avail.start_time,
        end_time: avail.end_time
      )
    end

    appt.save!(validate: false)

    appt
  end

  def ensure_availability_service_radius(avail, patient)
    # NOTE: allow all patient if avaibility location info is not present
    # Might we need to raise an error
    if avail.service_radius? && avail.latitude? && avail.longitude?
      if patient.latitude? && patient.longitude?
        distance = Geocoder::Calculations.distance_between(
          [patient.latitude, patient.longitude],
          [avail.latitude, avail.longitude]
        ).round
      else
        raise Error, 'Patient location is not recognized.'
      end
    else
      distance = 0
    end

    if distance > avail.service_radius
      raise Error, 'Patient location is out of service radius.'
    end
  end
end
