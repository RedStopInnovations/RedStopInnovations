module Settings
  class StripeIntegrationController < ApplicationController
    STRIPE_ACCESS_DENIED_CODE = 'access_denied'

    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def show
      @stripe_account = current_business.stripe_account
    end

    def authorize
      redirect_to build_authorize_url, allow_other_host: true
    end

    def authorize_callback
      if params[:error].present?
        case params[:error]
        when STRIPE_ACCESS_DENIED_CODE
          redirect_to settings_stripe_integration_url,
                      alert: 'Stripe connect was cancelled.'
        else
          Sentry.capture_exception(
            StandardError.new("Stripe connect error: #{ params[:error] }")
          )
        end
      elsif params[:code].present?
        authorization_code = params[:code]
        res = Stripe::OAuth.token(
          client_secret: Rails.configuration.stripe[:secret_key],
          code: authorization_code,
          grant_type: 'authorization_code'
        )

        stripe_acc = BusinessStripeAccount.find_or_initialize_by(
          business_id: current_business.id
        )

        stripe_acc.assign_attributes(
          account_id: res.stripe_user_id,
          access_token: res.access_token,
          refresh_token: res.refresh_token,
          publishable_key: res.stripe_publishable_key,
          connected_at: Time.current
        )
        stripe_acc.save!
        redirect_to settings_stripe_integration_url,
                    notice: 'Stripe account has been successfully connected.'
      else
        redirect_to settings_stripe_integration_url, alert: 'Bad request.'
      end
    end

    def deauthorize
      stripe_account = current_business.stripe_account
      if stripe_account
        begin
          Stripe::OAuth.deauthorize(
            client_id: ENV.fetch('STRIPE_CLIENT_ID'),
            stripe_user_id: stripe_account.account_id
          )
          stripe_account.destroy
          flash[:notice] = 'The Stripe account has been successfully disconnected.'
        rescue => e
          flash[:alert] = "An error has occurred. Error: #{ e.message }"
        end
      else
        flash[:alert] = 'Bad request.'
      end

      redirect_to settings_stripe_integration_url
    end

    private

    def build_authorize_url
      Stripe::OAuth.authorize_url(
        response_type: 'code',
        client_id: ENV.fetch('STRIPE_CLIENT_ID'),
        scope: 'read_write',
        redirect_uri: settings_stripe_connect_callback_url,
        always_prompt: true,
        stripe_user: {
          business_name: current_business.name,
          phone_number: current_business.phone,
          email: current_business.email,
        }
      )
    end
  end
end
