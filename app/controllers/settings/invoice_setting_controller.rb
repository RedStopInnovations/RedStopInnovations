module Settings
  class InvoiceSettingController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def show
      @form = UpdateInvoiceSettingsForm.build_for_business(current_business)
    end

    def update
      @form = UpdateInvoiceSettingsForm.new(update_params.merge(business: current_business))

      if @form.valid?
        invoice_setting = current_business.invoice_setting

        invoice_setting.assign_attributes @form.attributes.slice(:starting_invoice_number, :messages)
        invoice_setting.save!(validate: false)

        redirect_back fallback_location: settings_invoice_url,
                    notice: 'Invoice settings has been updated successfully.'
      else
        flash.now[:alert] = "Failed to update invoice settings. Please check for form errors."
        render :show
      end
    end

    private

    def update_params
      params.require(:invoice_settings).permit(
        :starting_invoice_number,
        :messages
      )
    end
  end
end
