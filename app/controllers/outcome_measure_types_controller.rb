class OutcomeMeasureTypesController < ApplicationController
  include HasABusiness

  before_action :find_outcome_measure_type, only: [:show, :edit, :update]

  def index
    @outcome_measure_types = current_business.
      outcome_measure_types.
      order(id: :desc).
      page(params[:page])
  end

  def show
  end

  def new
    @outcome_measure_type = OutcomeMeasureType.new(
      outcome_type: OutcomeMeasureType::OUTCOME_QUANTITATIVE
    )
  end

  def create
    @outcome_measure_type =
      current_business.outcome_measure_types.new(outcome_measure_type_params)

    if @outcome_measure_type.save
      redirect_to outcome_measure_type_url(@outcome_measure_type),
                  notice: 'The outcome measure type has ben successfully created.'
    else
      flash.now[:alert] = 'Failed to save measure type. Please check for form errors'
      render :new
    end
  end

  def update
    if @outcome_measure_type.update(outcome_measure_type_params)
      redirect_to outcome_measure_type_url(@outcome_measure_type),
                  notice: 'The outcome measure type has ben successfully updated.'
    else
      flash.now[:alert] = 'Failed to save measure type. Please check for form errors'
      render :edit
    end
  end

  private

  def outcome_measure_type_params
    params.required(:outcome_measure_type).permit(
      :name, :description, :outcome_type, :unit
    )
  end

  def find_outcome_measure_type
    @outcome_measure_type = current_business.outcome_measure_types.find(params[:id])
  end
end
