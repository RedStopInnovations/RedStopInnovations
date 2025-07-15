module Admin
  class SessionsController < Devise::SessionsController
    layout 'admin_auth'

    skip_before_action :verify_authenticity_token, only: :create

    def create
      _params = sign_in_params
      is_recaptcha_pass = App::RECAPTCHA_ENABLE ? verify_recaptcha : true

      if _params[:email].present? && _params[:password].present? &&
        (aUser = AdminUser.super_admin.find_by(email: _params[:email])) &&
        aUser.valid_password?(_params[:password]) &&
        is_recaptcha_pass

        if aUser.enabled_2fa? && aUser.mobile?
          raw_code = generate_verify_code
          send_verify_code(raw_code, aUser)
          store_verify_code(raw_code, aUser)

          session[:verifying_2fa_admin_user_id] = aUser.id
          redirect_to admin_sessions_verify_2fa_url,
                      warning: 'Please enter the code sent to your phone number.'
        else
          sign_in(resource_name, aUser)
          redirect_to after_sign_in_path_for(aUser)
        end
      else
        if !is_recaptcha_pass
          flash[:alert] = 'Please complete CAPTCHA correctly'
        else
          flash[:alert] = 'Wrong email or password'
        end

        redirect_to new_admin_user_session_url
      end
    end

    def verify_2fa
      if session[:verifying_2fa_admin_user_id] &&
        (aUser = AdminUser.find_by(id: session[:verifying_2fa_admin_user_id])) &&
        (aUser.has_pending_2fa_verification?)
      else
        redirect_to new_admin_user_session_path,
                    alert: 'Request not valid.'
      end
    end

    def post_verify_2fa
      if session[:verifying_2fa_admin_user_id] &&
        (aUser = AdminUser.find_by(id: session[:verifying_2fa_admin_user_id])) &&
        (aUser.has_pending_2fa_verification?)

        entered_code = params[:code].to_s.strip.presence

        if entered_code.present? &&
           (BCrypt::Password.new(aUser.encrypted_verify_code) == entered_code)
          session[:verifying_2fa_admin_user_id] = nil
          aUser.update_columns(
            encrypted_verify_code: nil,
            verify_code_expires_at: nil
          )
          sign_in(resource_name, aUser)
          redirect_to after_sign_in_path_for(aUser),
                      notice: 'Signed in successfully'
        else
          redirect_back fallback_location: admin_sessions_verify_2fa_url,
                        alert: 'Code is not valid'
        end

      else
        redirect_to new_admin_user_session_path,
                    alert: 'Request not valid.'
      end
    end

    def resend_verify_2fa_code
      if session[:verifying_2fa_admin_user_id] &&
        (aUser = AdminUser.find_by(id: session[:verifying_2fa_admin_user_id])) &&
        (aUser.has_pending_2fa_verification?)

        raw_code = generate_verify_code
        send_verify_code(raw_code, aUser)
        store_verify_code(raw_code, aUser)

        session[:verifying_2fa_admin_user_id] = aUser.id
        redirect_to admin_sessions_verify_2fa_url,
                    warning: 'New verification code sent to your phone number.'
      else
        redirect_to new_admin_user_session_path,
                    alert: 'Request not valid.'
      end
    end

    protected

    def after_sign_in_path_for(admin_user)
      if admin_user.is_receptionist?
        admin_reception_search_practitioner_path
      else
        stored_location_for(admin_user) || admin_dashboard_path
      end
    end

    def after_sign_out_path_for(admin_user)
      new_admin_user_session_path
    end

    def send_verify_code(code, aUser)
      TwilioService.new(
        to_number: aUser.mobile,
        message: "System 2FA code: #{code}",
        from: ENV.fetch('TWILIO_NUMBER', 'System')
      ).send_sms
    end

    def store_verify_code(code, aUser)
      aUser.encrypted_verify_code = BCrypt::Password.create(code)
      aUser.verify_code_expires_at = 5.minutes.from_now
      aUser.save!(validate: false)
    end

    def generate_verify_code
      rand(100000...999999).to_s
    end
  end
end
