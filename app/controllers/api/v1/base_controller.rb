module Api
  module V1
    class BaseController < ActionController::API

      include JsonApiHelper
      include PaginationHelpers
      before_action :skip_session
      before_action :authorize_user
      before_action :better_errors_fix, if: -> { Rails.env.development? }

      rescue_from ActiveRecord::RecordNotFound do |e|
        render_not_found
      end

      protected

      def authorize_user
        api_key = ApiKey.active.find_by(token: request_api_key)

        if api_key.present? && api_key.user.present?
          user = api_key.user
          if user.role_administrator?
            set_api_user(user)
            log_api_key_usage(api_key)
          else
            render_unauthorized
          end
        else
          render_unauthorized
        end
      end

      def request_api_key
        key = request.headers['X-API-KEY']
        # Accept api_key in url on development
        if key.blank? && Rails.env.development?
          key = params[:api_key]
        end

        key
      end

      # Workaround for better_error page very slow to show the right panel
      def better_errors_fix
        request.env['puma.config'].options.user_options.delete :app
      end

      def skip_session
        request.session_options[:skip] = true
      end

      def set_api_user(user)
        @api_user = user
      end

      def api_user
        @api_user
      end

      def current_business
        @api_user.business
      end

      def render_unauthorized
        render json: { error: 'Unauthorized' }, status: :forbidden
      end

      def render_not_found
        render json: { error: 'Not found' }, status: :not_found
      end

      def log_api_key_usage(api_key)
        api_key.update_columns(
          last_used_at: Time.current,
          last_used_by_ip: request.remote_ip
        )
      end

      private

      def jsonapi_filter_key
        :filter
      end

      # Whitelited filter params. Default is empty for better security.
      def jsonapi_whitelist_filter_params
        []
      end

      def jsonapi_filter_params
        @jsonapi_filter_params ||= begin
          if params[jsonapi_filter_key].present?
            params[jsonapi_filter_key].to_unsafe_h.slice *jsonapi_whitelist_filter_params
          end
        end
      end
    end
  end
end
