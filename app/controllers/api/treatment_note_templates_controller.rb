module Api
  class TreatmentNoteTemplatesController < BaseController
    before_action :set_treatment_note_template, only: [:show, :update, :destroy]

    def show
      render json: { treatment_note_template: @treatment_note_template }
    end

    def create
      @treatment_note_template = current_business.treatment_note_templates.build(treatment_note_template_params)

      if @treatment_note_template.save
        render json: {
          success: true,
          message: 'Template created successfully',
          redirect_url: treatment_note_templates_path,
          treatment_note_template: @treatment_note_template
        }, status: :created
      else
        render json: {
          success: false,
          errors: @treatment_note_template.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def update
      if @treatment_note_template.update(treatment_note_template_params)
        render json: {
          success: true,
          message: 'Template updated successfully',
          treatment_note_template: @treatment_note_template
        }
      else
        render json: {
          success: false,
          errors: @treatment_note_template.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def destroy
      @treatment_note_template.destroy
      head :no_content
    end

    private

    def set_treatment_note_template
      @treatment_note_template = current_business.treatment_note_templates.find(params[:id])
    end

    def treatment_note_template_params
      params.require(:treatment_note_template).permit(:name, :content, :html_content)
    end
  end
end