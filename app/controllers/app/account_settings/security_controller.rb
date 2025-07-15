module App
  module AccountSettings
    class SecurityController < ApplicationController
      include HasABusiness

      def index
        @login_activity = LoginActivity.where(user: current_user).order(id: :desc).limit(10)
      end
    end
  end
end