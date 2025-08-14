class TreatmentNoteTemplatesController < ApplicationController
  include HasABusiness

  def index
    @treatment_note_templates = current_business.treatment_note_templates.not_deleted.order(name: :asc).page(params[:page])
  end

  def new
    @treatment_note_template = TreatmentNoteTemplate.new
  end

  def show
    @treatment_note_template = current_business.treatment_note_templates.find(params[:id])
  end

  def edit
    @treatment_note_template = current_business.treatment_note_templates.find(params[:id])
  end

  def destroy
    @treatment_note_template = current_business.treatment_note_templates.find(params[:id])
    @treatment_note_template.soft_delete(author: current_user)
    redirect_to treatment_note_templates_path, notice: 'Treatment note template was successfully destroyed.'
  end
end
