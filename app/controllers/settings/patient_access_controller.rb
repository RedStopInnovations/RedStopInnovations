module Settings
  class PatientAccessController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def show
      @patient_access_settings = PatientAccessSetting.find_or_create_by!(
        business_id: current_business.id
      )
    end

    def save_settings
      @patient_access_settings = PatientAccessSetting.find_or_create_by!(
        business_id: current_business.id
      )
      if @patient_access_settings.update(save_settings_params)
        redirect_to settings_patient_access_url,
                    notice: 'Settings successfully updated.'
      else
        render :show
      end
    end

    private

    def save_settings_params
      params.require(:patient_access_setting).permit(:enable)
    end
  end
end
