module Settings
  class BusinessController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    before_action :set_setting

    def storage_documents; end

    def sms_sender_id; end

    # @TODO: rewrite this, should have it own action
    def update
      if @setting.update(setting_params)
        redirect_back fallback_location: settings_url, notice: "Settings has been updated successfully"
      else
        flash.now[:alert] = "Please check for form errrors"
        render :storage_documents
      end
    end

    private

    def set_setting
      @setting = current_business.setting || current_business.create_setting
    end

    def setting_params
      params.require(:business_setting).permit(:storage_url)
    end
  end
end
