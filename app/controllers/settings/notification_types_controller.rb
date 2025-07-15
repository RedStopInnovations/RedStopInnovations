module Settings
  class NotificationTypesController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def index
      @notification_type_settings = NotificationTypeSetting.
        includes(:notification_type).
        where(business_id: current_business.id).
        order(id: :asc)
    end

    def edit
      @notification_type_setting = NotificationTypeSetting.where(business_id: current_business.id).find(params[:id])
    end

    def update
      # @TODO: validate
      @notification_type_setting = NotificationTypeSetting.where(business_id: current_business.id).find(params[:id])

      if @notification_type_setting.update update_params
        redirect_to settings_notification_types_path,
                    notice: 'Notification settings has been successfully updated.'
      else
        flash.now[:alert] = 'Failed to update notification settings. Please check for form errors.'
        render :edit
      end
    end

    private

    def update_params
      params.require(:setting).permit(
        :enabled,
        enabled_delivery_methods: [],
        template: [:email_subject, :email_body, :sms_content]
      )
    end
  end
end