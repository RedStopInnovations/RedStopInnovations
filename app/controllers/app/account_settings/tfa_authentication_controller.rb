module App
  module AccountSettings
    class TfaAuthenticationController < ApplicationController
      include HasABusiness

      def setup
        if current_user.enable_google_authenticator?
          redirect_back fallback_location: app_account_settings_security_path,
                        alert: 'The 2FA is already enabled.'
        else
          if current_user.google_secret_value.nil? || (
            current_user.google_authenticator_secret_created_at.nil? || current_user.google_authenticator_secret_created_at <= 1.hours.ago
          )
            # @TODO: The secret should be stored in session before user has successfully enabled 2FA
            current_user.set_google_secret
            current_user.update_column :google_authenticator_secret_created_at, Time.current
          end
        end
      end

      def modal_disable
      end

      def enable
        user = current_user

        if user.enable_google_authenticator?
          redirect_back fallback_location: app_account_settings_security_path,
                        alert: 'The 2FA is already enabled.'
        else
          if user.valid_password?(params[:current_password]) && user.google_authentic?(params[:code])
            user.update_attribute :enable_google_authenticator, true
            ::UserMfaSession.create(user)

            redirect_to app_account_settings_security_path,
                        notice: 'The 2FA has been successfully enabled.'
          else
            error_msg =
              if !user.valid_password?(params[:current_password])
                'The current password is incorrect'
              elsif !user.google_authentic?(params[:code])
                'The 2FA code is incorrect'
              end

            redirect_to app_account_settings_tfa_authentication_setup_path,
                        alert: error_msg
          end
        end
      end

      def disable
        user = current_user

        if user.valid_password?(params[:current_password]) && user.google_authentic?(params[:code])
          user.update(
            enable_google_authenticator: false,
            google_authenticator_secret: nil,
            google_authenticator_secret_created_at: nil
          )

          ::UserMfaSession::destroy

          redirect_to app_account_settings_security_path,
                      notice: 'The 2FA has been successfully disabled.'
        else
          error_msg =
            if !user.valid_password?(params[:current_password])
              'The current password is incorrect'
            elsif !user.google_authentic?(params[:code])
              'The 2FA code is incorrect'
            end

          redirect_to app_account_settings_security_path,
                      alert: error_msg
        end
      end
    end
  end
end