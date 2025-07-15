module App
  module AccountSettings
    class ProfileController < ApplicationController
      include HasABusiness

      def index
        @user = current_user
        @form = UpdateMyprofileForm.build_from(@user)
      end

      def update
        @user = current_user

        @form = UpdateMyprofileForm.new(profile_params.merge(
          user: @user
        ))

        if @form.valid?
          UpdateMyprofileService.new.call(@user, @form)
          redirect_to app_account_settings_profile_path, notice: 'Your profile was successfully updated.'
        else
          flash.now[:alert] = 'Failed to update profile. Please check for form errors.'
          render :index, status: 422
        end
      end

      def change_signature
        @form = UpdatePractitionerSignatureForm.new(update_signature_params)
        @user = current_user

        @success = false
        @error_msg = nil
        @practitioner = current_user.practitioner

        if @user.is_practitioner?
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
            end
          else
            @error_msg = "Validation error: #{@form.errors.full_messages.join(', ')}"
          end
        else
          @error_msg = 'Bad request. User is not a practitioner.'
        end
      end

      def update_avatar
        @user = current_user

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

      def pre_change_password
        @user = current_user
      end

      def update_password
        @user = current_user
        if @user.update_with_password(update_password_params)
          bypass_sign_in @user
        end
      end

      def modal_practitioner_documents
        @practitioner = current_user.practitioner
        respond_to do |f|
          f.js
        end
      end

      def update_practitioner_document
        if current_user.is_practitioner?
          form = UpdatePractitionerDocumentForm.new(update_practitioner_document_params)

          if form.valid?
            UpdatePractitionerDocumentService.new.call(current_user.practitioner, form)
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
        else
          render(
            json: {
              message: 'The user is not a practitioner.'
            },
            status: 400
          )
        end
      end

      def delete_practitioner_document
        type = params[:type]

        if current_user.is_practitioner?
          document = current_user.practitioner.documents.find_by(type: type)
          if document
            document.destroy
          end
          redirect_back fallback_location: dashboard_url,
                notice: 'The document has been successfully deleted.'
        else
          redirect_back fallback_location: dashboard_url,
                alert: 'The user is not a practitioner.'
        end
      end

      protected

      def profile_params
        params.require(:user).permit(
          :first_name,
          :last_name,
          :email,
          :timezone,
          :profession,
          :medicare,
          :phone,
          :mobile,
          :email,
          :address1,
          :address2,
          :city,
          :state,
          :postcode,
          :country,
          :summary,
          :education
        )
      end

      def update_password_params
        params.require(:user).permit(
          :current_password,
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
    end
  end
end