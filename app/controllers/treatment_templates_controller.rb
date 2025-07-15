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
    @treatment_template.user_ids = current_business.users.pluck(:id)
  end

  def create
    @treatment_template = current_business.treatment_templates.new(template_params)

    if @treatment_template.save
      flash[:notice] = 'Treatment note template was successfully created.'
      respond_to do |f|
        f.html do
          redirect_to treatment_template_path(@treatment_template)
        end
        f.json do
          render json: {
            treatment_template: @treatment_template
          }
        end
      end
    else
      respond_to do |f|
        f.html { render :new }
        f.json do
          render(
            json: { errors: @treatment_template.errors.full_messages },
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
      flash[:notice] = 'Treatment note template was successfully updated.'
      respond_to do |f|
        f.html do
          redirect_to treatment_template_path(@treatment_template)
        end
        f.json do
          render json: {
            treatment_template: @treatment_template
          }
        end
      end
    else
      flash[:notice] = 'Failed to update treatment note template.'
      respond_to do |f|
        f.html { render :new }
        f.json do
          render(
            json: { errors: @treatment_template.errors.full_messages },
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

  def sections_form
    render partial: 'sections_form',
           locals: { sections: @treatment_template.template_sections }
  end

  private

  def set_treatment_template
    @treatment_template = current_business.treatment_templates.find(params[:id])
  end

  def template_params
    params.require(:treatment_template).permit(
      :name,
      template_sections: [
        :name,
        questions: [
          :name,
          :type,
          :required,
          answer: [:content],
          answers: [:content]
        ]
      ],
      user_ids: []
    )
  end
end
