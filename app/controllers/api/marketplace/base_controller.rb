module Api
  module Marketplace
    class BaseController < ActionController::API
      before_action :skip_session
      before_action :authorize_marketplace
      before_action :better_errors_fix, if: -> { Rails.env.development? }

      protected

      def authorize_marketplace
        authorized = false
        if request_api_key.to_s.strip.present?
          marketplace = ::Marketplace.find_by(api_key: request_api_key)
          if marketplace.present?
            authorized = true
            set_marketplace(marketplace)
          end
        end

        unless authorized
          render_unauthorized
        end
      end

      def request_api_key
        request.headers['X-API-KEY']
      end

      def better_errors_fix
        request.env['puma.config'].options.user_options.delete :app
      end

      def skip_session
        request.session_options[:skip] = true
      end

      def set_marketplace(marketplace)
        @current_marketplace = marketplace
      end

      def current_marketplace
        @current_marketplace
      end

      def render_unauthorized
        # head :unauthorized
        render json: {},
              status: :unauthorized
      end
    end
  end
end
