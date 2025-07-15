module Settings
  class MarketingTrackingController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def index
      @google_tag_manager_settings = load_google_tag_manager_settings
    end

    def update_google_tag_manager
      save_google_tag_manager_settings(
        params.require(:google_tag_manager).permit(:container_id).to_h
      )

      redirect_back fallback_location: settings_path,
                    notice: 'Google Tag Manager settings has been updated'
    end

    private

    def load_google_tag_manager_settings
      BusinessSetting.find_or_initialize_by(business_id: current_business.id).google_tag_manager
    end

    def save_google_tag_manager_settings(update_params)
      business_settings = BusinessSetting.find_or_initialize_by(business_id: current_business.id)

      # @TODO: validate and clean up values
      # Regex to validate GTM container ID: /^GTM-[A-Z0-9]{1,10}$/
      business_settings.google_tag_manager = update_params.transform_values(&:presence)

      business_settings.save!
    end
  end
end