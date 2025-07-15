module App
  module AccountSettings
    class ApiKeysController < ApplicationController
      include HasABusiness

      def index
        @api_keys = ApiKey.active.where(user_id: current_user.id).order(id: :desc)
      end

      def create
        if ApiKey.active.where(user_id: current_user.id).count >= App::MAX_USER_API_KEYS
          redirect_to app_account_settings_api_keys_path,
                        alert: "You can create up to #{App::MAX_USER_API_KEYS} API keys."
        else
          @api_key = ApiKey.new(
            user_id: current_user.id,
            active: true
          )
          @api_key.token = ApiKey.generate_token
          @api_key.save!

          redirect_to app_account_settings_api_keys_path,
                        notice: "An API key was successfully created."
        end
      end

      def destroy
        @api_key = ApiKey.where(user_id: current_user.id).find(params[:id])
        @api_key.deactivate!

        redirect_to app_account_settings_api_keys_path,
                      notice: "The API key successfully deleted."
      end
    end
  end
end