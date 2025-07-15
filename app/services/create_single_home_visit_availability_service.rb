class CreateSingleHomeVisitAvailabilityService
  REPEAT_TYPE_DAILY = 'daily'
  REPEAT_TYPE_WEEKLY = 'weekly'
  REPEAT_TYPE_MONTHLY = 'monthly'

  attr_reader :business, :form_request

  def call(business, form_request)
    @business = business
    @form_request = form_request
    result = OpenStruct.new
    avail = build_availability
    avail.business_id = business.id
    repeat_avails = []
    first_appt = nil

    Availability.transaction do
      if repeat?
        avail_recurring = create_availability_recurring(avail)
        avail.recurring_id = avail_recurring.id
      end

      avail.save!(validate: false)

      first_appt = build_appointment(avail)
      first_appt.save!(validate: false)

      if repeat?
        repeat_avails = create_repeats(avail)
      end

      result.success = true
      result.availability = avail
    end

    if avail.persisted?
      # Calculate routes and stats
      HomeVisitRouting::ArrivalCalculate.new.call(avail.id)
      AvailabilityCachedStats.new.update(avail)

      repeat_avails.each do |repeat_avail|
        HomeVisitRouting::ArrivalCalculate.new.call(repeat_avail.id)
        AvailabilityCachedStats.new.update(repeat_avail)
      end

      # Notifications and reminders
      if first_appt && first_appt.persisted?
        send_booking_confirmations(first_appt)
        schedule_appointment_reminder(first_appt)
        trigger_webhook(first_appt)
        grant_patient_access(first_appt)
      end

      repeat_avails.each do |repeat_avail|
        appt = repeat_avail.appointments.first
        if appt
          schedule_appointment_reminder(appt)
          trigger_webhook(appt)
        end
      end

      # Sync external calendars
      if avail.practitioner&.user&.google_calendar_sync_setting&.status_active?
        SyncAvailabilityToGoogleCalendarWorker.perform_async(avail.id)

        repeat_avails.each do |repeat_avail|
          SyncAvailabilityToGoogleCalendarWorker.perform_async(repeat_avail.id)
        end
      end

    else
      result.success = false
    end

    result
  end

  private

  def repeat?
    form_request.repeat_type.present?
  end

  def build_availability
    avail = Availability.new(
      form_request.attributes.slice(
        :practitioner_id,
        :start_time,
        :end_time,
        :address1,
        :city,
        :state,
        :postcode,
        :country
      )
    )
    avail.assign_attributes(
      availability_type_id: AvailabilityType::TYPE_HOME_VISIT_ID,
      service_radius: 10,
      max_appointment: 1,
      allow_online_bookings: false
    )

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

  def build_appointment(availability)
    appt = Appointment.new(
      appointment_type_id: form_request.appointment_type_id,
      patient_case_id: form_request.patient_case_id.presence,
      practitioner_id: form_request.practitioner_id,
      patient_id: form_request.patient_id,
      availability_id: availability.id,
      start_time: availability.start_time,
      end_time: availability.end_time,
      order: 0
    )
    appt
  end

  def create_repeats(source_avail)
    repeats = []
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
          :allow_online_bookings
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
          raise "Unknown repeat type: #{form_request.repeat_type}"
        end

      if source_avail.latitude? && source_avail.longitude?
        repeat_avail.latitude     = source_avail.latitude
        repeat_avail.longitude    = source_avail.longitude
      end
      repeat_avail.recurring_id = source_avail.recurring_id
      repeat_avail.save!(validate: false)

      # Add repeat appointment
      repeat_appt = build_appointment(repeat_avail)
      repeat_appt.save!(validate: false)
      repeats << repeat_avail
      last_repeat = repeat_avail
    end

    repeats
  end

  # Send booking confirmation to patient and practitioner
  def send_booking_confirmations(appointment)
    patient = appointment.patient

    if appointment.start_time.future? &&
      patient.reminder_enable? &&
      patient.email? &&
      appointment.appointment_type.reminder_enable? &&
      business.communication_template_enabled?('appointment_confirmation')
        AppointmentMailer.booking_confirmation(appointment.id).deliver_later
    end

    SendAppointmentNotificationJob.perform_later(appointment.id, NotificationType::APPOINTMENT__CREATED)
  end

  def schedule_appointment_reminder(appointment)
    patient = appointment.patient

    if appointment.start_time.future? && patient.reminder_enable? && appointment.appointment_type.reminder_enable?
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

  def trigger_webhook(appointment)
    Webhook::Worker.perform_later(
      appointment.id,
      'appointment_created'
    )
  end

  def grant_patient_access(appointment)
    PatientAccess.
      where(user_id: appointment.practitioner.user_id, patient_id: appointment.patient.id).
      first_or_create
  end
end
