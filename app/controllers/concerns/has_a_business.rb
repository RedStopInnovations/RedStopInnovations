module HasABusiness
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    helper_method :current_business
    before_action :check_mfa_authentication
  end

  def current_business
    @current_business ||= current_user.business
  end

  private

  def check_mfa_authentication
    if current_user && current_user.enable_google_authenticator?
      user_mfa_session = UserMfaSession.find

      unless user_mfa_session&.record == current_user
        redirect_to app_mfa_authentication_verify_path
      end
    end
  end
end
