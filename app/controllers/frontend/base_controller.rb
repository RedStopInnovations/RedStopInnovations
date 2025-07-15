module Frontend
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception

    layout 'frontend/layouts/main'

    if Rails.env.production?
      rescue_from StandardError do |e|
        Sentry.capture_exception(e)
        render_server_error
      end

      rescue_from ActionController::UnknownFormat do |e|
        render_not_found
      end
    end

    protected

    def render_not_found
      respond_to do |f|
        f.json do
          render json: { error: 'Not found' } , status: :not_found
        end
        f.html do
          render 'errors/404', layout: false, status: :not_found
        end
        f.pdf do
          head :not_found
        end
      end
    end

    def render_server_error
      respond_to do |f|
        f.json do
          render json: { message: 'Server errror' }, status: 500
        end
        f.html do
          render 'errors/500', layout: false, status: 500
        end
      end
    end
  end
end