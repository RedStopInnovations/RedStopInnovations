module App
  module AccountSettings
    class TimeableSettingsController < ApplicationController
      include HasABusiness
      before_action :require_practitioner_user_only

      def index
        @business_hours = current_user.practitioner.business_hours.to_a
      end

      def update_business_hours
        # form = UpdatePractitionerBusinessHoursForm.new update_params

        if true || form.valid?
          UpdateBusinessHoursService.new.call(current_user.practitioner, params.to_unsafe_h)
        else
        end
      end

      private

      def require_practitioner_user_only
        unless current_user.is_practitioner?
          redirect_back fallback_location: app_account_settings_profile_path, notice: 'The user is not a practitioner.'
        end
      end

      def update_params
        params.require(:business_hours).permit!
      end
    end
  end
end