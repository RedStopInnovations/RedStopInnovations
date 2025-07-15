module Settings
  class MailchimpsController < ApplicationController
    include HasABusiness


    before_action do
      authorize! :read, :reports
    end

    before_action :set_mailchimp, only: [:index, :create]

    def index
    end

    def create
      @mailchimp_setting.assign_attributes params.require(:business_mailchimp_setting)
                                                  .permit(:list_name, :api_key)

      if @mailchimp_setting.save
        BusinessMailchimpSyncPatients.perform_later(current_business)
        redirect_to settings_mailchimps_url,
                    notice: 'Mailchimp setting has been successfully updated.'
      else
        flash.now[:alert] = 'Failed to update Mailchimp setting. Please check for form errors.'
        render :index
      end
    end

    private
    def set_mailchimp
      @mailchimp_setting = current_business.mailchimp_setting || current_business.build_mailchimp_setting
    end
  end
end
