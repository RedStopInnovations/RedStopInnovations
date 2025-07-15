module Settings
  class PhysitrackIntegrationController< ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :physitrack_integration
    end

    def show
      @physitrack_integration = find_or_build_integration_settings
    end

    def update
      @physitrack_integration = find_or_build_integration_settings

      @physitrack_integration.assign_attributes(update_params)

      if @physitrack_integration.save
        redirect_to settings_physitrack_integration_url,
                    notice: 'The settings has been updated'
      else
        flash.now[:alert] = 'Could not save settings. Please check for form errors.'
        render :show
      end
    end

    private

    def find_or_build_integration_settings
      settings = current_business.physitrack_integration

      if settings.nil?
        settings = PhysitrackIntegration.new(
          enabled: false,
          business: current_business
        )
      end

      settings
    end

    def update_params
      params.require(:physitrack_integration).permit(:enabled)
    end
  end
end
