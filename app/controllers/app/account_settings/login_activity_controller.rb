module App
  module AccountSettings
    class LoginActivityController < ApplicationController
      include HasABusiness

      def index
        @login_activity = LoginActivity.where(user: current_user).order(id: :desc).page(params[:page])
      end
    end
  end
end