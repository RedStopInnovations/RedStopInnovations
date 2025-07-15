module App
  class MfaAuthenticationController < ApplicationController
    include HasABusiness

    skip_before_action :check_mfa_authentication, only: [:verify, :verify_code]

    def verify
      render layout: 'auth'
    end

    def verify_code
      @user = current_user

      if params[:code].present? && @user.google_authentic?(params[:code].to_s )
        UserMfaSession.create(@user)
        redirect_to dashboard_path
      else
        redirect_to app_mfa_authentication_verify_path,
                    alert: 'The 2FA code is invalid.'
      end
    end
  end
end