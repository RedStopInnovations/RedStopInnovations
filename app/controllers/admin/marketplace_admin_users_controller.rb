module Admin
  class MarketplaceAdminUsersController < BaseController
    before_action do
      authorize! :manage, :marketplace_admin_users
    end

    before_action :find_marketplace
    before_action :find_admin_user, only: [:show, :edit, :update, :resend_invitation]

    def index
      @admin_users = @marketplace.admin_users
    end

    def new
      @admin_user = AdminUser.new
    end

    def create
      @admin_user = AdminUser.new(create_params)
      @admin_user.assign_attributes(
        marketplace_id: @marketplace.id,
        role: AdminUser::MARKETPLACE_ADMIN_ROLE,
        password: Devise.friendly_token.first(15)
      )

      if @admin_user.save
        @admin_user.invite!
        redirect_to admin_marketplace_admin_users_url(@marketplace),
                    notice: 'The user was successfully created' \
                            '. An invitation email has been sent'
      else
        flash.now[:alert] = 'Please check for form errors.'
        render :new
      end
    end

    def edit
    end

    def update
      if @admin_user.update(update_params)
        redirect_to admin_marketplace_admin_user_url(@marketplace, @admin_user),
                    notice: 'The user was successfully updated.'
      else
        flash.now[:alert] = 'Please check for form errors.'
        render :edit
      end
    end

    def resend_invitation
      if @admin_user.has_pending_invitation?
        @admin_user.invite!
        flash[:success] = "A new invitation email has been successfully sent."
      else
        flash[:alert] = "The user has no pending invitation."
      end
      redirect_back(
        fallback_location: admin_marketplace_admin_user_url(@marketplace, @admin_user)
      )
    end

    private

    def find_marketplace
      @marketplace = ::Marketplace.find(params[:marketplace_id])
    end

    def find_admin_user
      @admin_user = @marketplace.admin_users.find(params[:id])
    end

    def create_params
      params.require(:admin_user).permit(
        :first_name,
        :last_name,
        :email
      )
    end

    def update_params
      permitted_attributes = [
        :first_name,
        :last_name,
        :email,
        :active,
        :password,
        :password_confirmation
      ]

      permitted_params = params.require(:admin_user).permit permitted_attributes

      if permitted_params[:password].blank?
        permitted_params.delete :password
        permitted_params.delete :password_confirmation
      end

      permitted_params
    end
  end
end
