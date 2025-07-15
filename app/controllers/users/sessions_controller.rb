class Users::SessionsController < Devise::SessionsController
  layout 'auth', only: [:new]

  protect_from_forgery except: [:create]

  def create
    super
    flash[:after_sign_in] = true
  end

  def after_sign_in_path_for(user)
    dashboard_path
  end

  def after_sign_out_path_for(user)
    begin
      UserMfaSession::destroy
    rescue => e
      Sentry.capture_exception(e)
    end
    new_user_session_path
  end
end
