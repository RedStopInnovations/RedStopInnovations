class CaseTypesController < ApplicationController
  include HasABusiness

  before_action do
    authorize! :manage, CaseType
  end

  before_action :find_case_type, only: [:edit, :update, :destroy]

  def index
    @search_query = current_business.
      case_types.
      not_deleted.
      ransack(params[:q].try(:to_unsafe_h))

    @cases = @search_query.
      result.
      order(title: :asc).
      page(params[:page])
  end

  def new
    @case = CaseType.new
  end

  def create
    @case = current_business.case_types.new case_type_params
    if @case.save
      redirect_to case_types_url,
                    notice: 'The case type has been successfully created.'
    else
      flash.now[:alert] = 'Failed to create case type. Please check for form errors.'
      render :new
    end
  end

  def edit
  end

  def update
    if @case.update(case_type_params)
      redirect_to case_types_url,
                    notice: 'The case type has been successfully updated.'
    else
      flash.now[:alert] = 'Failed to update case type. Please check for form errors.'
      render :edit
    end
  end

  def destroy
    @case.update_column :deleted_at, Time.current
    redirect_to case_types_url,
                notice: 'The case type has been successfully deleted.'
  end

  private

  def case_type_params
    params.require(:case_type).permit(:title, :description)
  end

  def find_case_type
    @case = current_business.case_types.find params[:id]
  end
end
