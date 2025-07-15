module Admin
  class ProfileController < BaseController
    def show
      @admin_user = current_admin_user
    end

    def update
      @admin_user = current_admin_user
      _params = profile_params

      success = if _params.key?(:password)
        @admin_user.update_with_password(profile_params)
      else
        @admin_user.update(profile_params)
      end

      if success
        redirect_to admin_profile_url,
                    notice: 'Your profile has been successfully updated.'
      else
        flash.now[:alert] = 'Failed to update profile. Please check for form errors'
        render :show
      end
    end

    protected

    def profile_params
      permitted_attributes = [
        :first_name,
        :last_name,
        :password,
        :password_confirmation,
        :current_password
      ]

      permitted_params = params.require(:admin_user).permit permitted_attributes

      # Remove password params if empty
      if permitted_params[:password].blank?
        permitted_params.delete :password
        permitted_params.delete :password_confirmation
        permitted_params.delete :current_password
      end

      permitted_params
    end
  end
end
