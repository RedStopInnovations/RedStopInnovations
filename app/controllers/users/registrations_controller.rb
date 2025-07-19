class Users::RegistrationsController < Devise::RegistrationsController
  layout "auth", only: [:new, :create]

  def new
    country_code = current_country
    time_zone = TZInfo::Country.get(country_code)

    @form = RegistrationForm.new country: country_code
    @form.timezone = time_zone.zone_identifiers.first if country_code != "AU"
  end

  def create
    redirect_back fallback_location: new_user_registration_path, alert: "Registration is not allowed at this time."

    return

    @form = RegistrationForm.new(registration_params)

    is_recaptcha_pass = App::RECAPTCHA_ENABLE ? verify_recaptcha : true
    form_valid = @form.valid?

    if is_recaptcha_pass && form_valid
      user = RegistrationService.new.call(@form)
      sign_in user
      redirect_to after_sign_up_path_for(user)
    else
      if !is_recaptcha_pass
        flash.now[:alert] = "Please complete CAPTCHA correctly"
      end
      render :new
    end
  end

  private

  def registration_params
    params.require(:registration).permit(
      :business_name,
      :first_name,
      :last_name,
      :email,
      :timezone,
      :password,
      :password_confirmation,
      :country,
    )
  end

  def after_sign_up_path_for(user)
    dashboard_path
  end
end
