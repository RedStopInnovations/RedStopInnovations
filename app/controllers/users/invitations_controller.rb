class Users::InvitationsController < Devise::InvitationsController
  layout 'auth'

  private

  def after_accept_path_for(user)
    flash[:after_sign_in] = true
    dashboard_path
  end
end
