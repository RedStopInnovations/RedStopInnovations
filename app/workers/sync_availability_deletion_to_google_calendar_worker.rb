class SyncAvailabilityDeletionToGoogleCalendarWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3

  # @param Integer availability_id
  # NOTE: Soft-deletion is not implemented for availability records
  def perform(availability_id)
    first_appt = Appointment.with_deleted.where(availability_id: availability_id).first
    if first_appt
      user = first_appt.practitioner&.user
      gcal_sync_setting = user&.google_calendar_sync_setting

      if user && gcal_sync_setting
        Appointment.with_deleted.where(availability_id: availability_id).each do |appt|
          sync_record = UserGoogleCalendarSyncRecord.where(sync_object: appt, user_id: user.id).first
          if sync_record
            if gcal_sync_setting.status_active?
              begin
                gcal_service = build_google_calendar_service(gcal_sync_setting.access_token)
                gcal_service.delete_event(gcal_sync_setting.calendar_id, sync_record.calendar_event_id)
              rescue Google::Apis::Error => e
                # Do nothing
              end
            end

            sync_record.delete
          end
        end
      end

    else
      sync_record = UserGoogleCalendarSyncRecord.where(sync_object_id: availability_id, sync_object_type: 'Availability').first
      if sync_record
        user = User.find_by(id: sync_record.user_id)
        gcal_sync_setting = user&.google_calendar_sync_setting

        if user && gcal_sync_setting && gcal_sync_setting.status_active?
          begin
            gcal_service = build_google_calendar_service(gcal_sync_setting.access_token)
            gcal_service.delete_event(gcal_sync_setting.calendar_id, sync_record.calendar_event_id)
          rescue Google::Apis::Error => e
            # Do nothing
          end
        end

        sync_record.delete
      end
    end
  end

  private

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