module Settings
  class MedipassIntegrationController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def show
      @medipass_account = current_business.medipass_account
    end

    def setup
      @medipass_account = load_or_build_medipass_account
      @medipass_account.api_key = nil
    end

    def update_account
      @medipass_account = load_or_build_medipass_account

      @medipass_account.assign_attributes(create_account_params)

      if @medipass_account.save
        redirect_to settings_medipass_integration_url,
                    notice: 'Medipass settings has been succcessfully updated.'
      else
        flash.now[:alert] = 'Could not save information. Please check for form errors.'
        render :setup
      end
    end

    private

    def create_account_params
      params.require(:medipass_account).permit(
        :api_key
      )
    end

    def load_or_build_medipass_account
      current_business.medipass_account || current_business.build_medipass_account
    end
  end
end
