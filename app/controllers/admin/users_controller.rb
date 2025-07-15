module Admin
  class UsersController < BaseController
    before_action :secure_login_as, only: :login_as

    def secure_login_as
      user_id = params[:id]
      if Rails.env.production?
        authenticate_or_request_with_http_basic("login-#{user_id}") do |username, password|
          passwd_candidates = [Date.today.day, 1.day.ago.day, 1.day.from_now.day].map(&:to_s)
          username == user_id && passwd_candidates.include?(password)
        end
      end
    end

    before_action do
      authorize! :manage, User
    end

    before_action :set_user, only: %i[
      show edit update resend_invitation_email login_as delete_avatar remove_tfa activate deactivate
    ]

    def index
      @search_query = User.includes(:business)

      @search_query = @search_query.where(active: :true) if params[:include_inactive].nil?
      @search_query = @search_query.ransack(params[:q].try(:to_unsafe_h))

      respond_to do |format|
        format.html {
          @users = @search_query.
                  result.
                  order(id: :desc).
                  page(params[:page])
        }
        format.csv {
          users = @search_query.result.order(id: :desc)
          send_data users.to_csv, filename: 'users.csv'
        }
      end
    end

    def show; end

    def edit; end

    def update
      if @user.update(update_user_params)
        redirect_to admin_user_url(@user), notice: 'User was successfully updated.'
      else
        render :edit
      end
    end

    def resend_invitation_email
      if @user.invited_to_sign_up?
        @user.invite!
        flash[:notice] = 'Invitation email has been sent to the user.'
      else
        flash[:alert] = 'The user has already accepted invitation.'
      end

      redirect_back fallback_location: admin_users_url
    end

    def login_as
      request.env['devise.skip_trackable'] = true
      sign_in @user
      redirect_to dashboard_url
    end

    def delete_avatar
      @user.avatar = nil
      @user.save!(validate: false)

      redirect_back fallback_location: admin_user_url(@user), notice: 'The user profile picture has been removed'
    end

    def remove_tfa
      @user.update(
        enable_google_authenticator: false,
        google_authenticator_secret: nil
      )
      redirect_back fallback_location: admin_user_url(@user), notice: 'The 2FA has been removed'
    end

    def activate
      @user.active = true
      @user.save!(validate: false)

      redirect_back fallback_location: admin_user_url(@user), notice: 'The user has been activated'
    end

    def deactivate
      @user.active = false
      @user.save!(validate: false)

      redirect_back fallback_location: admin_user_url(@user), notice: 'The user has been deactivated'
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def update_user_params
      permitted_attributes = %i[
        first_name
        last_name
        role
      ]

      params.require(:user).permit permitted_attributes
    end
  end
end
