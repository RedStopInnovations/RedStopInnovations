module Settings
  class UsersController < ApplicationController
    include HasABusiness

    before_action :set_user, only: [
      :show, :edit, :update, :change_signature, :resend_invitation_email,
      :update_avatar,
      :allocated_items,
      :update_allocated_appointment_types,
      :update_allocated_billable_items,
      :update_allocated_treatment_templates,
      :login_activity,
      :modal_practitioner_documents,
      :update_practitioner_document,
      :delete_practitioner_document,
      :timeable_settings,
      :update_business_hours,
      :send_reset_password_email,
      :update_password,
      :remove_2fa
    ]

    before_action do
      authorize! :manage, User
    end

    before_action :require_practitioner_user, only: [
      :change_signature,
      :modal_practitioner_documents,
      :update_practitioner_document,
      :delete_practitioner_document,
      :timeable_settings,
      :update_business_hours
    ]

    def index
      @search_query =
        if params[:include_inactive] == '1'
          current_business.users
        else
          current_business.users.active
        end

        if params[:practitioner_only] == '1'
          @search_query = @search_query.where(is_practitioner: true)
        end

      @search_query = @search_query.includes(:practitioner).ransack(params[:q].try(:to_unsafe_h))
      @users = @search_query.
                  result.
                  order(id: :desc).
                  page(params[:page])
    end

    def show
      @practitioner = @user.practitioner
    end

    def new
      @form = CreateUserForm.new(
        role: User::PRACTITIONER_ROLE,
        send_invitation_email: true,
        is_practitioner: true,
        timezone: current_user.timezone,
        country: current_business.country
      )
    end

    def create
      @form = CreateUserForm.new(create_user_params)

      if @form.valid?
        result = CreateUserService.new.call(current_business, current_user, @form)
        user = result.user
        redirect_to settings_user_url(user), notice: 'The user was successfully created'
      else
        flash.now[:alert] = 'Failed to create user. Please check for form errors.'
        render :new, status: 422
      end
    end

    def edit
      @form = UpdateUserForm.build_from(@user)
    end

    def update
      @form = UpdateUserForm.new(update_user_params.merge(
        user: @user
      ))

      if @form.valid?
        UpdateUserService.new.call(current_business, @user, @form)
        redirect_to edit_settings_user_url(@user), notice: 'The user details was successfully updated.'
      else
        flash.now[:alert] = 'Failed to update user. Please check for form errors.'
        render :edit, status: 422
      end
    end

    def change_signature
      @form = UpdatePractitionerSignatureForm.new(update_signature_params)

      @success = false
      @error_msg = nil
      @practitioner = @user.practitioner

      if @form.valid?
        begin
          if @form.signature_image_data_url.present?
            parsed_img_data = Utils::Image.parse_from_data_url(@form.signature_image_data_url)
            fake_file = Extensions::FakeFileIo.new(
              "#{Time.current.to_i}.#{parsed_img_data[:extension]}",
              Base64.decode64(parsed_img_data[:data])
            )

            @practitioner.assign_attributes signature: fake_file
          else
            @practitioner.assign_attributes signature: @form.signature_image_file
          end

          @practitioner.save!(validate: false)
          @success = true
        rescue => e
          @error_msg = 'Cannot update signature. An error has occurred. '
          Sentry.capture_exception(e)
        end
      else
        @error_msg = "Validation error: #{@form.errors.full_messages.join(', ')}"
      end
    end

    def resend_invitation_email
      if @user.invited_to_sign_up?
        @user.invite!
        flash[:notice] = 'Invitation email has been sent to the user.'
      else
        flash[:alert] = 'The user has already accepted invitation.'
      end

      redirect_back fallback_location: settings_users_url
    end

    def update_avatar
      avatar_data_url = params.fetch(:avatar_data_url)
      parsed_img_data = Utils::Image.parse_from_data_url(avatar_data_url)

      if parsed_img_data
        generated_file_name = "#{Time.current.to_i}.#{parsed_img_data[:extension]}"

        file = Extensions::FakeFileIo.new(
          generated_file_name,
          Base64.decode64(parsed_img_data[:data])
        )

        @user.update_attribute :avatar, file
        render json: {
          avatar: {
            medium: @user.avatar.url(:medium, timestamp: true),
            thumb: @user.avatar.url(:thumb, timestamp: true)
          }
        }
      else
        render json: {
          message: 'Invalid format of profile picture.'
        }, status: 400
      end
    end

    def allocated_items
      @appointment_types = current_business.appointment_types.not_deleted.order(name: :asc).to_a
      @billable_items = current_business.billable_items.not_deleted.order(name: :asc).to_a
      @treatment_templates = current_business.treatment_templates.order(name: :asc)

      if @user.is_practitioner?
        practitioner = @user.practitioner
        @allocated_appointment_type_ids = practitioner.appointment_types.pluck(:id)
        @allocated_billable_item_ids = practitioner.billable_items.pluck(:id)
      end

      @allocated_treatment_template_ids = @user.accessible_treatment_templates.pluck(:id)
    end

    def update_allocated_appointment_types
      if @user.is_practitioner?
        practitioner = @user.practitioner
        selected_ids = params.permit(ids: [])[:ids]

        if selected_ids.blank?
          sanitized_ids = []
        else
          sanitized_ids = current_business.appointment_types.where(id: selected_ids).pluck(:id)
        end

        practitioner.appointment_type_ids = sanitized_ids
        practitioner.save!(validate: false)
        head :no_content
      else
        render json: {
          message: 'This user is not a practitioner'
        }, status: 400
      end
    end

    def update_allocated_billable_items
      if @user.is_practitioner?
        practitioner = @user.practitioner
        selected_ids = params.permit(ids: [])[:ids]

        if selected_ids.blank?
          sanitized_ids = []
        else
          sanitized_ids = current_business.billable_items.where(id: selected_ids).pluck(:id)
        end

        practitioner.billable_item_ids = sanitized_ids
        practitioner.save!(validate: false)
        head :no_content
      else
        render json: {
          message: 'This user is not a practitioner'
        }, status: 400
      end
    end

    def update_allocated_treatment_templates
      selected_ids = params.permit(ids: [])[:ids]

      if selected_ids.blank?
        sanitized_ids = []
      else
        sanitized_ids = current_business.treatment_templates.where(id: selected_ids).pluck(:id)
      end

      @user.accessible_treatment_template_ids = sanitized_ids
      @user.save!(validate: false)
      head :no_content
    end

    def login_activity
      @login_activity = LoginActivity.where(user: @user).order(id: :desc).page(params[:page])
    end

    def modal_practitioner_documents
      @practitioner = @user.practitioner
      respond_to do |f|
        f.js
      end
    end

    def update_practitioner_document
      form = UpdatePractitionerDocumentForm.new(update_practitioner_document_params)

      if form.valid?
        UpdatePractitionerDocumentService.new.call(@user.practitioner, form)
        render(
          json: {
            message: 'The document has been successfully updated.'
          }
        )
      else
        render(
          json: {
            message: 'Failed not save document. Please check for form merrors.',
            errors: form.errors.full_messages
          },
          status: 422
        )
      end
    end

    def delete_practitioner_document
      type = params[:type]

      if @user.is_practitioner?
        document = @user.practitioner.documents.find_by(type: type)
        if document
          document.destroy
        end
        redirect_back fallback_location: edit_settings_user_url(@user),
              notice: 'The document has been successfully deleted.'
      else
        redirect_back fallback_location: edit_settings_user_url(@user),
              alert: 'The user is not a practitioner.'
      end
    end

    def timeable_settings
      @business_hours = @user.practitioner.business_hours.to_a
    end

    def update_business_hours
      # form = UpdatePractitionerBusinessHoursForm.new update_params

      if true || form.valid?
        UpdateBusinessHoursService.new.call(@user.practitioner, params.to_unsafe_h)
      else
      end
    end

    def update_password
      if !@user.role_administrator?
        form = UpdateUserPasswordForm.new(params.permit(
          :password,
          :password_confirmation
        ))

        if form.valid?
          @user.password = form.password

          if @user.invited_to_sign_up?
            @user.invitation_token = nil # Force remove pending invitation
          end

          @user.save!(validate: false)

          redirect_back fallback_location: edit_settings_user_url(@user),
                        notice: "The password has been successfully updated."
        else
          redirect_back fallback_location: edit_settings_user_url(@user), alert: "Validation error: #{form.errors.full_messages.first}"
        end
      else
        redirect_back fallback_location: edit_settings_user_url(@user), alert: 'Change password for admin user is not allowed.'
      end
    end

    def send_reset_password_email
      @user.send_reset_password_instructions

      redirect_back fallback_location: edit_settings_user_url(@user),
                    notice: "The reset password instruction email will be sent to the user."
    end

    def remove_2fa
      if @user.enable_google_authenticator?
        @user.update_columns(
          enable_google_authenticator: false,
          google_authenticator_secret: nil,
          google_authenticator_secret_created_at: nil,
          updated_at: Time.current
        )

        redirect_back fallback_location: settings_user_url(@user),
                      notice: "The 2FA has been disabled for the account."
      else
        redirect_back fallback_location: settings_user_url(@user),
                      alert: "The 2FA is currently not enabled for the account."
      end
    end

    private

    def set_user
      @user = current_business.users.find(params[:id])
    end

    def update_user_params
      params.require(:user).permit(
        :first_name,
        :last_name,
        :email,
        :timezone,
        :is_practitioner,
        :active,
        :role,
        :employee_number,
        :profession,
        :medicare,
        :phone,
        :mobile,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country,
        :summary,
        :education,
        :allow_online_bookings
      )
    end

    def create_user_params
      params.require(:user).permit(
        :first_name,
        :last_name,
        :email,
        :avatar_data_url,
        :timezone,
        :is_practitioner,
        :role,
        :employee_number,

        :profession,
        :medicare,
        :phone,
        :mobile,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country,

        :summary,
        :education,
        :allow_online_bookings,

        :send_invitation_email,
        :password,
        :password_confirmation
      )
    end

    def update_signature_params
      params.permit(:signature_image_data_url, :signature_image_file)
    end

    def update_practitioner_document_params
      params.require(:document).permit(:type, :file, :expiry_date)
    end

    def require_practitioner_user
      unless @user.is_practitioner?
        respond_to do |f|
          f.html {
            redirect_back fallback_location: edit_settings_user_url(@user),
                  alert: 'The user is not a practitioner.'
          }

          f.json do
            render(
              json: {
                message: 'The user is not a practitioner.'
              },
              status: 400
            )
          end
        end
      end
    end
  end
end
