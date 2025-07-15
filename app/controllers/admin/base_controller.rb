module Admin
  class BaseController < ApplicationController
    layout 'admin'
    before_action :authenticate_admin_user!

    rescue_from CanCan::AccessDenied do |exception|
      msg = 'The page does not exist or you are not authorized.'
      respond_to do |format|
        format.html { redirect_to after_unauthorized_path, alert: msg }
        format.json { head :forbidden, content_type: 'text/html' }
        format.js   { head :forbidden, content_type: 'text/html' }
        format.csv  {
          redirect_to after_unauthorized_path, alert: msg
        }
      end
    end

    def set_time_zone
      timezone =
        if current_admin_user
          current_admin_user.timezone
        else
          App::DEFAULT_TIME_ZONE
        end
      Time.use_zone(timezone) { yield }
    end

    def current_ability
      @current_ability ||= AdminUserAbility.new(current_admin_user)
    end

    protected

    def after_unauthorized_path
      if admin_user_signed_in?
        admin_dashboard_path
      else
        root_path
      end
    end
  end
end
