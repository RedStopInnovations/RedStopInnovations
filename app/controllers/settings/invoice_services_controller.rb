module Settings
  class InvoiceServicesController < ApplicationController
    include HasABusiness

    before_action :find_shortcut, only: [:destroy, :edit, :update]

    def index
      @services = current_business.invoice_shortcuts.services
                                   .page(params[:page])
    end

    def new
      @shortcut = current_business.invoice_shortcuts.new
    end

    def create
      @shortcut = current_business.invoice_shortcuts.new shortcut_params.merge(category: InvoiceShortcut::CATEGORY_SERVICE)
      
      if @shortcut.save
        redirect_to settings_invoice_services_path,
                    notice: "Service has been created successfully"
      else
        flash.now[:alert] = "Failed to create service. Please check for form errors."
        render :new
      end
    end

    def edit; end

    def update
      if @shortcut.update shortcut_params
        redirect_to settings_invoice_services_path,
                    notice: "Service has been updated successfully"
      else
        flash.now[:alert] = "Failed to update service. Please check for form errors."
        render :edit
      end
    end

    def destroy
      @shortcut.destroy
      redirect_to settings_invoice_services_path,
                  notice: "Service has been deleted successfully"
    end

    private
    def find_shortcut
      @shortcut = current_business.invoice_shortcuts.services.find(params[:id])
    end

    def shortcut_params
      params.require(:invoice_shortcut).permit(:content)
    end
  end
end