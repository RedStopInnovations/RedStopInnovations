module Settings
  class TreatmentShortcutsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    before_action :find_shortcut, only: [:destroy, :edit, :update]

    def index
      @shortcuts = current_business.treatment_shortcuts
                                  .order(content: :asc)
                                  .page(params[:page])
    end

    def new
      @shortcut = current_business.treatment_shortcuts.new
    end

    def create
      @shortcut = current_business.treatment_shortcuts.new shortcut_params

      if @shortcut.save
        redirect_to settings_treatment_shortcuts_path,
                    notice: "Shortcut has been created successfully"
      else
        flash.now[:alert] = "Failed to create shortcut. Please check for form errors."
        render :new
      end
    end

    def edit; end

    def update
      if @shortcut.update shortcut_params
        redirect_to settings_treatment_shortcuts_path,
                    notice: "Shortcut has been updated successfully"
      else
        flash.now[:alert] = "Failed to update shortcut. Please check for form errors."
        render :edit
      end
    end

    def destroy
      @shortcut.destroy
      redirect_to settings_treatment_shortcuts_path,
                  notice: "Shortcut has been deleted successfully"
    end

    private
    def find_shortcut
      @shortcut = current_business.treatment_shortcuts.find(params[:id])
    end

    def shortcut_params
      params.require(:treatment_shortcut).permit(:content)
    end
  end
end