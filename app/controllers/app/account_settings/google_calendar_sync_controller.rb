module App
  module AccountSettings
    class GoogleCalendarSyncController < ApplicationController
      include HasABusiness

      def index
        @current_setting = UserGoogleCalendarSyncSetting.find_by(user_id: current_user.id)
      end

      def authorize
        redirect_to build_authorize_url, allow_other_host: true
      end

      def authorize_callback
        begin
          if params[:error].present?
            redirect_to app_account_settings_google_calendar_sync_path,
                        alert: 'Cancelled connect to Google account'
          elsif params[:code].present?
            oauth_client = Signet::OAuth2::Client.new(oauth_client_options)
            oauth_client.code = params[:code]
            oauth_response = oauth_client.fetch_access_token!

            user_setting = UserGoogleCalendarSyncSetting.find_or_initialize_by(user_id: current_user.id)
            user_setting.calendar_id = 'primary'
            user_setting.access_token = oauth_response['access_token']
            user_setting.refresh_token = oauth_response['refresh_token']
            user_setting.access_token_expires_at = Time.current + oauth_response['expires_in']
            user_setting.connected_at = Time.current
            user_setting.status = UserGoogleCalendarSyncSetting::STATUS_ACTIVE

            user_setting.save!

            redirect_to app_account_settings_google_calendar_sync_path,
                        notice: 'Your Google account is successfully connected.'
          else
            redirect_to app_account_settings_google_calendar_sync_path,
                        alert: 'Bad request'
          end
        rescue => e
          Sentry.capture_exception e
          redirect_to app_account_settings_google_calendar_sync_path,
                      alert: 'An error has occurred. Sorry for the inconvenience.'
        end
      end

      def deauthorize
        current_setting = UserGoogleCalendarSyncSetting.find_by(user_id: current_user.id)
        if current_setting
          begin
            # TODO: deauthorize
            current_setting.destroy
            flash[:notice] = 'The Google account has been successfully disconnected.'
          rescue => e
            flash[:alert] = "An error has occurred. Error: #{ e.message }"
          end
        else
          flash[:alert] = 'Bad request.'
        end

        redirect_to app_account_settings_google_calendar_sync_path
      end

      private

      def oauth_client_options
        {
          authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
          token_credential_uri: 'https://oauth2.googleapis.com/token',
          client_id: ENV["GOOGLE_CALENDAR_APP_CLIENT_ID"],
          client_secret: ENV["GOOGLE_CALENDAR_APP_CLIENT_SECRET"],
          scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
          redirect_uri: app_account_settings_google_calendar_sync_authorize_callback_url,
          grant_type: :refresh_token
        }
      end

      def build_authorize_url
        oauth_client = Signet::OAuth2::Client.new oauth_client_options
        oauth_client.authorization_uri(prompt: :consent, access_type: :offline).to_s
      end
    end
  end
end

