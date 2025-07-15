class LetterTemplatesController < ApplicationController
  include HasABusiness

  before_action only: [:edit, :update, :destroy] do
    authorize! :manage, LetterTemplate
  end

  before_action :set_letter_template, only: [
    :show, :edit, :update, :destroy, :preview
  ]

  def index
    @letter_templates = current_business.letter_templates.order(name: :asc)
  end

  def show
    redirect_to edit_letter_template_url(@letter_template)
  end

  def new
    @letter_template = LetterTemplate.new
  end

  def preview
    business = current_business
    patient = current_business.patients.find_by(id: params[:patient_id])
    practitioner = current_user.practitioner

    result = Letter::Renderer.new(patient, @letter_template).render([
      business,
      practitioner
    ].compact, hightlight_missing: true)

    render json: { letter: result }
  end

  def edit
  end

  def create
    @letter_template = current_business.letter_templates.new(letter_template_params)

    if @letter_template.save
      redirect_to letter_templates_url,
                  notice: 'Letter template was successfully created.'
    else
      render :new
    end
  end

  def update
    if @letter_template.update(letter_template_params)
      redirect_to letter_templates_url,
                  notice: 'Letter template was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @letter_template.destroy
    redirect_to letter_templates_url,
                notice: 'Letter template was successfully destroyed.'
  end

  private

  def set_letter_template
    @letter_template = current_business.letter_templates.find(params[:id])
  end

  def letter_template_params
    params.require(:letter_template).permit(
      :name, :content, :email_subject
    )
  end
end
