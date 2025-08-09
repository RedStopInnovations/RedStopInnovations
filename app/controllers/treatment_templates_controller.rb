class TreatmentTemplatesController < ApplicationController
  include HasABusiness

  before_action :set_treatment_template, except: [:index, :new, :create]

  def index
    @treatment_templates = current_business.treatment_templates.order(name: :asc).page(params[:page])
  end

  def show
  end

  def new
    @treatment_template = TreatmentTemplate.new
  end

  def create
    @treatment_template = current_business.treatment_templates.new(template_params)

    if @treatment_template.save
      respond_to do |f|
        f.html do
          redirect_to edit_treatment_template_path(@treatment_template)
        end
        f.json do
          render json: {
            success: true,
            message: 'Treatment note template was successfully created.',
            treatment_template: @treatment_template,
            redirect_url: edit_treatment_template_path(@treatment_template)
          }
        end
      end
    else
      respond_to do |f|
        f.html { render :new }
        f.json do
          render(
            json: {
              success: false,
              errors: @treatment_template.errors.full_messages
            },
            status: 422
          )
        end
      end
    end
  end

  def edit
  end

  def update
    if @treatment_template.update(template_params)
      respond_to do |f|
        f.html do
          redirect_to edit_treatment_template_path(@treatment_template)
        end
        f.json do
          render json: {
            success: true,
            message: 'Treatment note template was successfully updated.',
            treatment_template: @treatment_template
          }
        end
      end
    else
      respond_to do |f|
        f.html { render :edit }
        f.json do
          render(
            json: {
              success: false,
              errors: @treatment_template.errors.full_messages
            },
            status: 422
          )
        end
      end
    end
  end

  def destroy
    @treatment_template.destroy_by_author(current_user)
    redirect_to treatment_templates_path,
                notice: 'Treatment note template was successfully deleted.'
  end

  private

  def set_treatment_template
    @treatment_template = current_business.treatment_templates.find(params[:id])
  end

  def template_params
    params.require(:treatment_template).permit(
      :name,
      :content,
      :html_content
    )
  end
end
