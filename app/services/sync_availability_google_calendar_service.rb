class SyncAvailabilityGoogleCalendarService
  # TODO: stop sync if time is in the past
  # Remaining issues:
  #  - If user delete the event on their Google calendar but not on our platform, the appointment will be never be synced again
  def call(availability_id)
    @availability = Availability.find(availability_id)
    @practitioner = @availability.practitioner
    @user = @practitioner.user
    @sync_settings = @user.google_calendar_sync_setting

    return if @sync_settings.nil? || !@sync_settings.status_active?

    if @availability.home_visit?
      sync_home_visit
    elsif @availability.non_billable?
      sync_non_billable
    elsif @availability.group_appointment?
      sync_group_appointment
    end
  end

  private

  # Sync appointments
  def sync_home_visit
    google_calendar_service = build_google_calendar_service(@sync_settings.access_token)

    Appointment::where(availability_id: @availability.id).with_deleted.each do |appt|
      sync_record = UserGoogleCalendarSyncRecord::find_or_initialize_by(
        user_id: @user.id,
        sync_object: appt,
        calendar_id: @sync_settings.calendar_id
      )

      if appt.cancelled_at? || appt.deleted_at?
        if sync_record.persisted?
          # Delete event
          begin
            google_calendar_service.delete_event(@sync_settings.calendar_id, sync_record.calendar_event_id)

          rescue Google::Apis::Error => e
            # Do nothing
          ensure
            sync_record.destroy
          end
        end
      else
        do_sync = false
        appt_state = build_appointment_sync_state(appt)
        do_sync = sync_record.new_record? || sync_record.last_sync_state.nil? || (sync_record.last_sync_state.with_indifferent_access != appt_state.with_indifferent_access)

        if do_sync
          sync_record.assign_attributes(
            last_sync_state: appt_state,
            last_sync_at: Time.current
          )

          calendar_event = build_event_object_for_appointment(appt)
          begin
            if sync_record.persisted?
              begin
                google_calendar_service.update_event(@sync_settings.calendar_id, sync_record.calendar_event_id, calendar_event)
              rescue Google::Apis::ClientError => e
                if e.status_code == 404
                  # Maybe the event is deleted by the user, recreate it!
                  calendar_event = google_calendar_service.insert_event(@sync_settings.calendar_id, calendar_event)
                  sync_record.calendar_event_id = calendar_event.id
                else
                  raise e
                end
              end
            else
              calendar_event = google_calendar_service.insert_event(@sync_settings.calendar_id, calendar_event)
              sync_record.calendar_event_id = calendar_event.id
            end

            sync_record.save
          rescue Google::Apis::Error => e
            case e
            when Google::Apis::AuthorizationError
              # TODO: when AuthorizationError, mark sync setting status to error?
            else
              Sentry.capture_exception(e)
            end
          end
        end
      end
    end
  end

  # Sync availability as a event
  def sync_non_billable
    google_calendar_service = build_google_calendar_service(@sync_settings.access_token)

    sync_record = UserGoogleCalendarSyncRecord::find_or_initialize_by(
      user_id: @user.id,
      sync_object: @availability,
      calendar_id: @sync_settings.calendar_id
    )

    do_sync = false
    avail_state = build_nonbillable_availability_sync_state(@availability)
    do_sync = sync_record.new_record? || sync_record.last_sync_state.nil? || (sync_record.last_sync_state.with_indifferent_access != avail_state.with_indifferent_access)

    if do_sync
      sync_record.assign_attributes(
        last_sync_state: avail_state,
        last_sync_at: Time.current
      )
      calendar_event = build_event_object_for_nonbillable_availability(@availability)
      begin
        if sync_record.persisted?
          begin
            google_calendar_service.update_event(@sync_settings.calendar_id, sync_record.calendar_event_id, calendar_event)
          rescue Google::Apis::ClientError => e
            if e.status_code == 404
              # Maybe the event is deleted by the user, recreate it!
              calendar_event = google_calendar_service.insert_event(@sync_settings.calendar_id, calendar_event)
              sync_record.calendar_event_id = calendar_event.id
            else
              raise e
            end
          end
        else
          calendar_event = google_calendar_service.insert_event(@sync_settings.calendar_id, calendar_event)
          sync_record.calendar_event_id = calendar_event.id
        end

        sync_record.save
      rescue Google::Apis::Error => e
        case e
        when Google::Apis::AuthorizationError
          # TODO: when AuthorizationError, mark sync setting status to error?
        else
          Sentry.capture_exception(e)
        end
      end
    end
  end

  # Sync availability as a event
  def sync_group_appointment
    google_calendar_service = build_google_calendar_service(@sync_settings.access_token)

    sync_record = UserGoogleCalendarSyncRecord::find_or_initialize_by(
      user_id: @user.id,
      sync_object: @availability,
      calendar_id: @sync_settings.calendar_id
    )

    do_sync = false
    avail_state = build_group_appoinment_availability_sync_state(@availability)
    do_sync = sync_record.new_record? || sync_record.last_sync_state.nil? || (sync_record.last_sync_state.with_indifferent_access != avail_state.with_indifferent_access)

    if do_sync
      sync_record.assign_attributes(
        last_sync_state: avail_state,
        last_sync_at: Time.current
      )
      calendar_event = build_event_object_for_group_appointment_availability(@availability)
      begin
        if sync_record.persisted?
          begin
            google_calendar_service.update_event(@sync_settings.calendar_id, sync_record.calendar_event_id, calendar_event)
          rescue Google::Apis::ClientError => e
            if e.status_code == 404
              # Maybe the event is deleted by the user, recreate it!
              calendar_event = google_calendar_service.insert_event(@sync_settings.calendar_id, calendar_event)
              sync_record.calendar_event_id = calendar_event.id
            else
              raise e
            end
          end
        else
          calendar_event = google_calendar_service.insert_event(@sync_settings.calendar_id, calendar_event)
          sync_record.calendar_event_id = calendar_event.id
        end

        sync_record.save
      rescue Google::Apis::Error => e
        case e
        when Google::Apis::AuthorizationError
          # TODO: when AuthorizationError, mark sync setting status to error?
        else
          Sentry.capture_exception(e)
        end
      end
    end
  end

  def build_nonbillable_availability_sync_state(availability)
    state = {
      practitioner_id: availability.practitioner_id,
      start_time_timestamp: availability.start_time.to_i,
      end_time_timestamp: availability.end_time.to_i,
      name: availability.name,
      contact_id: availability.contact_id,
      description: availability.description.presence
    }
  end

  def build_group_appoinment_availability_sync_state(availability)
    state = {
      practitioner_id: availability.practitioner_id,
      start_time_timestamp: availability.start_time.to_i,
      end_time_timestamp: availability.end_time.to_i,
      description: availability.description.presence,
      group_appointment_type_id: availability.group_appointment_type_id,
      contact_id: availability.contact_id
    }
  end

  # A token represents appointment state to detect whether need to be sync again or not
  def build_appointment_sync_state(appointment)
    state = {
      patient_id: appointment.patient_id,
      availability_id: appointment.availability_id,
      practitioner_id: appointment.practitioner_id,
      appointment_type_id: appointment.appointment_type.id,
      duration: appointment.appointment_type.duration,
      start_time_timestamp: appointment.start_time.to_i,
      end_time_timestamp: appointment.end_time.to_i,
      location: appointment.patient.full_address
    }

    if appointment.arrival&.arrival_at?
      state[:arrival_at_timestamp] = appointment.arrival&.arrival_at.to_i
    end

    # Digest::MD5.hexdigest state.to_json
    state
  end

  def build_event_object_for_nonbillable_availability(availability)
    event_start_at = availability.start_time
    event_end_at = availability.end_time
    event_summary = availability.name
    event_desc = availability.description

    # @TODO: add non-billable type if present?

    calendar_event = Google::Apis::CalendarV3::Event.new(
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: event_start_at.rfc3339),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: event_end_at.rfc3339),
      summary: event_summary,
      description: event_desc,
      location: availability.full_address
    )

    calendar_event
  end

  def build_event_object_for_group_appointment_availability(availability)
    event_start_at = availability.start_time
    event_end_at = availability.end_time
    event_summary = availability.group_appointment_type&.name || 'Group appointment'
    event_desc = availability.description

    calendar_event = Google::Apis::CalendarV3::Event.new(
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: event_start_at.rfc3339),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: event_end_at.rfc3339),
      summary: event_summary,
      description: event_desc,
      location: availability.full_address
    )

    calendar_event
  end

  def build_event_object_for_appointment(appointment)
    arrival_at = appointment.arrival&.arrival_at
    event_start_at = arrival_at.present? ? arrival_at : appointment.start_time
    event_end_at = event_start_at + appointment.appointment_type.duration.minutes
    patient = appointment.patient
    event_summary = "Appointment with #{appointment.patient.full_name}"
    event_desc = "Appointment type: #{appointment.appointment_type.name}.\nAddress: #{patient.short_address}.\n"

    if patient.mobile?
      event_desc << "\nMobile: #{patient.mobile}"
    end

    if patient.phone?
      event_desc << "\nTel: #{patient.phone}"
    end

    unless arrival_at.present?
      event_desc << "\nNote: The exact arrival time was not calculated"
    end

    calendar_event = Google::Apis::CalendarV3::Event.new(
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: event_start_at.rfc3339),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: event_end_at.rfc3339),
      summary: event_summary,
      description: event_desc
    )

    if appointment.home_visit?
      calendar_event.location = patient.full_address
    end

    calendar_event
  end

  def build_google_calendar_service(access_token)
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = Signet::OAuth2::Client.new(
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      client_id: ENV["GOOGLE_CALENDAR_APP_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CALENDAR_APP_CLIENT_SECRET"],
      access_token: access_token
    )
    service
  end
end