module Admin
  class ReceptionistsController < BaseController
    before_action :set_receptionist, only: [:show, :edit, :update, :destroy]

    def index
      @search_query = AdminUser.receptionist

      @search_query = @search_query.where(active: :true) if params[:include_inactive].nil?
      @search_query = @search_query.ransack(params[:q].try(:to_unsafe_h))

      @receptionists = @search_query.result
        .order(id: :desc)
        .page(params[:page])
    end

    def show
    end

    def new
      @receptionist = AdminUser.new
    end

    def edit
    end

    def create
      @receptionist = AdminUser.receptionist.new(create_receptionist_params)

      @receptionist.password = Devise.friendly_token.first(15)

      if @receptionist.save
        @receptionist.invite!
        redirect_to admin_receptionist_url(@receptionist),
                    notice: 'Receptionist was successfully created'\
                            '. An invitation email has been sent'
      else
        flash.now[:alert] = 'Failed to create receptionist. Please check for form errors.'
        render :new
      end
    end

    def update
      if @receptionist.update(update_receptionist_params)
        redirect_to admin_receptionist_url(@receptionist),
                    notice: 'Receptionist was successfully updated.'
      else
        flash.now[:alert] = 'Failed to update receptionist. Please check for form errors.'
        render :edit
      end
    end

    def destroy
      @receptionist.destroy
      redirect_to admin_receptionists_url,
                  notice: 'Receptionist was successfully destroyed.'
    end

    private

    def set_receptionist
      @receptionist = AdminUser.receptionist.find(params[:id])
    end

    def create_receptionist_params
      params.require(:admin_user).permit(
        :first_name,
        :last_name,
        :email
      )
    end

    def update_receptionist_params
      permitted_attributes = [
        :first_name,
        :last_name,
        :email,
        :active,
        :password,
        :password_confirmation
      ]

      permitted_params = params.require(:admin_user).permit permitted_attributes

      # Remove password params if empty
      if permitted_params[:password].blank?
        permitted_params.delete :password
        permitted_params.delete :password_confirmation
      end

      permitted_params
    end
  end
end
