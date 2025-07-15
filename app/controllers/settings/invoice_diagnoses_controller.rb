module Settings
  class InvoiceDiagnosesController < ApplicationController
    include HasABusiness

    before_action :find_shortcut, only: [:destroy, :edit, :update]

    def index
      ahoy_track_once 'View invoice diagnosis report'

      @diagnoses = current_business.invoice_shortcuts.diagnoses
                                   .page(params[:page])
    end

    def new
      @shortcut = current_business.invoice_shortcuts.new
    end

    def create
      @shortcut = current_business.invoice_shortcuts.new shortcut_params.merge(category: InvoiceShortcut::CATEGORY_DIAGNOSE)

      if @shortcut.save
        redirect_to settings_invoice_diagnoses_path,
                    notice: "Diagnose has been created successfully"
      else
        flash.now[:alert] = "Failed to create diagnose. Please check for form errors."
        render :new
      end
    end

    def edit; end

    def update
      if @shortcut.update shortcut_params
        redirect_to settings_invoice_diagnoses_path,
                    notice: "Diagnose has been updated successfully"
      else
        flash.now[:alert] = "Failed to update diagnose. Please check for form errors."
        render :edit
      end
    end

    def destroy
      @shortcut.destroy
      redirect_to settings_invoice_diagnoses_path,
                  notice: "Diagnose has been deleted successfully"
    end

    private
    def find_shortcut
      @shortcut = current_business.invoice_shortcuts.diagnoses.find(params[:id])
    end

    def shortcut_params
      params.require(:invoice_shortcut).permit(:content)
    end
  end
end