class RefreshGoogleCalendarAuthorizationWorker
  include Sidekiq::Worker

  def perform
    UserGoogleCalendarSyncSetting.status_active.
      where('access_token_expires_at <= ?', Time.current + 5.minutes).
      find_each(batch_size: 100) do |setting|
        begin
          oauth_client = Signet::OAuth2::Client.new(
            authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
            token_credential_uri: 'https://oauth2.googleapis.com/token',
            client_id: ENV["GOOGLE_CALENDAR_APP_CLIENT_ID"],
            client_secret: ENV["GOOGLE_CALENDAR_APP_CLIENT_SECRET"],
            refresh_token: setting.refresh_token,
            grant_type: :refresh_token
          )
          oauth_response = oauth_client.refresh!
          setting.access_token = oauth_response['access_token']
          setting.access_token_expires_at = Time.current + oauth_response['expires_in']
          setting.save!
        rescue Google::Apis::AuthorizationError, Signet::AuthorizationError => e
          setting.status = UserGoogleCalendarSyncSetting::STATUS_ERROR
          setting.save!
        rescue => e
          Sentry.capture_exception e
        end
      end
  end
end
