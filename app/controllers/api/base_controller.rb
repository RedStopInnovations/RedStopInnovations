module Api
  class AccessDenied < StandardError; end

  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :set_locale
    before_action :authenticate_user
    skip_around_action :set_time_zone
    around_action :api_time_zone

    rescue_from Api::AccessDenied, CanCan::AccessDenied do
      respond_to do |format|
        format.json { render json: { error: 'Unauthorized', message: 'You are not authorized to perform the request.' }, status: :forbidden }
      end
    end

    protected

    def api_time_zone
      tz =
        if params[:timezone]
          params[:timezone]
        elsif request.headers['X-TZ']
          request.headers['X-TZ']
        elsif current_user
          current_user.timezone
        else
          App::DEFAULT_TIME_ZONE
        end
      Time.use_zone(tz) { yield }
    end

    def current_business
      @current_business ||= current_user.try(:business)
    end

    private

    def authenticate_user
      unless user_signed_in?
        respond_to do |f|
          f.json do
            render json: { error: 'Unauthorized', message: 'You are not authorized to perform the request.' }, status: :forbidden
          end
        end
      end
    end
  end
end
