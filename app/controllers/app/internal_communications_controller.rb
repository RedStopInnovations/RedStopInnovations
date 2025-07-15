module App
  class InternalCommunicationsController < ApplicationController
    include HasABusiness

    # Send email to another user
    def send_email
      form_request = SendInternalEmailForm.new params.permit(
        :user_id,
        :subject,
        :body
      ).merge(business: current_business)

      if form_request.valid?
        SendInternalEmailService.new.call(sender: current_user, form_request: form_request)

        respond_to do |f|
          f.json do
            render json: {
              message: "The email has been successfully sent."
            }
          end
          f.html do
            redirect_back fallback_location: dashboard_path, notice: "The email has been successfully sent."
          end
        end
      else
        respond_to do |f|
          f.json do
            render(json: {
              message: 'Failed to send email due to validation errors.',
              errors: form_request.errors.full_messages
            }, status: 422
            )
          end
          f.html do
            redirect_back fallback_location: dashboard_path, alert: "Validation errors: #{form_request.errors.full_messages.join('; ')}"
          end
        end
      end
    end
  end
end
