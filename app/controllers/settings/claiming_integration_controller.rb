module Settings
  class ClaimingIntegrationController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end
    before_action :ensure_claiming_auth_group_created,
                  only: [
                    :registered_providers,
                    :register_providers,
                    :post_register_providers
                  ]

    def show
      @claiming_auth_group = ClaimingAuthGroup.find_by(business_id: current_business.id)
    end

    def registered_providers
      @providers = @claiming_auth_group.providers.page(params[:page])
    end

    def setup
      @claiming_auth_group = current_business.claiming_auth_group
      if @claiming_auth_group
        redirect_to settings_claiming_integration_url,
                    alert: 'The integration is already setup.'
      else
        @registration_form =
          Claiming::AuthGroupRegistrationForm.build_from_business(current_business)

        @practitioners = current_business.practitioners.active
      end
    end

    def register_providers
      register_numbers = @claiming_auth_group.providers.pluck(:provider_number)
      @practitioners = current_business.practitioners.
        active.
        where.not(medicare: register_numbers).
        where("medicare <> ''").
        select('id, medicare, profession, first_name, last_name, full_name, email')
    end

    def post_register_providers
      practitioner_ids = current_business.practitioners.where(id: params[:practitioner_ids].to_a)
      if practitioner_ids.empty?
        redirect_back fallback_location: settings_claiming_integration_register_providers_url,
                      alert: 'Provider numbers list is empty'
      else
        # TODO: create details page for all results with error for each provider
        result = Claiming::ProvidersRegistrationService.new.call(current_business, practitioner_ids)
        if result.failure_practitioner_ids.size > 0
          flash[:alert] = 'Failed to register some provider numbers.'
        else
          flash[:notice] = 'The provider numbers has been successfully registered.'
        end
        redirect_to settings_claiming_integration_registered_providers_url
      end
    end

    def register
      @registration_form = Claiming::AuthGroupRegistrationForm.new(register_params)

      if @registration_form.valid?
        result =
          Claiming::CreateAuthGroupService.new.call(current_business, @registration_form)

        if result.success
          redirect_to settings_claiming_integration_url,
                      notice: 'Registration successfully.'
        else
          redirect_to settings_claiming_integration_url,
                      alert: 'Registration failed. An error has occurred.'
        end
      else
        redirect_to settings_claiming_integration_setup_url,
                    alert: "Form error: #{@registration_form.errors.full_messages.first}"
      end
    end

    private

    def register_params
      params.require(:registration).permit(:name, practitioner_ids: [])
    end

    def ensure_claiming_auth_group_created
      @claiming_auth_group = current_business.claiming_auth_group
      if @claiming_auth_group.nil?
        redirect_to settings_claiming_integration_url,
                    alert: 'The integration is not setup yet.'
      end
    end
  end
end
