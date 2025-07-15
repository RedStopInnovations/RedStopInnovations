class CreateAppointmentsService
  class Error < StandardError; end

  # Create one more many appointments for the same patient and appointment type to one or many availabilities
  # @param business Business
  # @param form CreateAppointmentsForm

  def call(business, form)
    @business = business
    @form = form

    @patient = business.patients.find form.patient_id
    @appointment_type = business.appointment_types.find(form.appointment_type_id)

    appointments = []
    availabilities = business.availabilities.where(id: form.availability_ids)

    Appointment.transaction do
      availabilities.each do |avail|
        last_appt_order = avail.appointments.maximum(:order) || -1

        appt = Appointment.new(
          availability: avail,
          practitioner: avail.practitioner,
          patient: @patient,
          appointment_type: @appointment_type,
          notes: form.notes.presence,
          start_time: avail.start_time,
          end_time: avail.end_time,
          order: last_appt_order + 1
        )

        if form.patient_case_id.present?
          appt.patient_case_id = form.patient_case_id
        end

        if avail.group_appointment?
          appt.appointment_type_id = avail.group_appointment_type_id
        end

        appt.save!(validate: false)
        appointments << appt

        if avail.home_visit?
          HomeVisitRouting::ArrivalCalculate.new.call(avail.id)
        elsif avail.facility?
          HomeVisitRouting::FacilityArrivalCalculate.new.call(avail.id)
        elsif avail.group_appointment?
          HomeVisitRouting::GroupAppointmentArrivalCalculate.new.call(avail.id)
        end

        AvailabilityCachedStats.new.update avail

        # Grant patient access to practitioner
        PatientAccess.
          where(user_id: avail.practitioner.user_id, patient_id: @patient.id).
          first_or_create
      end
    end

    first_appt = appointments.sort_by(&:start_time).first

    appointments.each do |appointment|
      if appointment.start_time.future?
        # Practitioner notifications
        SendAppointmentNotificationJob.perform_later(appointment.id, NotificationType::APPOINTMENT__CREATED)

        # Client notifications
        if @appointment_type.reminder_enable? && @patient.reminder_enable?
          # Only send a confirmation to the client for the first appointment
          if appointment.id == first_appt.id && business.communication_template_enabled?('appointment_confirmation') && @patient.email?
            AppointmentMailer.booking_confirmation(appointment.id).deliver_later
          end

          # Reminder schedule
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

      # Sync practitioner Google calendar
      if appointment.home_visit? && appointment.practitioner&.user&.google_calendar_sync_setting&.status_active?
        SyncAvailabilityToGoogleCalendarWorker.perform_async(appointment.availability_id)
      end

    end

    appointments
  end
end
