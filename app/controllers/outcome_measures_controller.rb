class OutcomeMeasuresController < ApplicationController
  include HasABusiness
  include PatientAccessRestriction

  before_action :find_patient
  before_action :authorize_patient_access
  before_action :outcome_measure, only: [
    :show, :edit, :update, :send_to_patient,
    :create_test, :update_test, :edit_test, :delete_test
  ]

  def index
    @outcome_measures = OutcomeMeasure.
      includes(:outcome_measure_type, :practitioner).
      where(patient_id: @patient.id).
      order(created_at: :desc).
      page(params[:page])
  end

  def show
    @outcome_measure_tests = @outcome_measure.tests.order(date_performed: :asc).load

    if @outcome_measure_tests.size > 0
      @chart = Report::Charts::OutcomeMeasure.new(@outcome_measure)
    end
  end

  def new
    @outcome_measure = OutcomeMeasure.new
  end

  def create
    @outcome_measure = @patient.outcome_measures.new(create_outcome_measure_params)

    if @outcome_measure.save
      redirect_to patient_outcome_measure_url(@patient, @outcome_measure),
                  notice: 'The outcome measure has been successfully created.'
    else
      flash.now[:alert] = 'Please check for form errors.'
      render :new
    end
  end

  def edit
  end

  def update
    if @outcome_measure.update(update_outcome_measure_params)
      redirect_to patient_outcome_measure_url(@patient, @outcome_measure),
                  notice: 'The outcome measure has been successfully updated.'
    else
      flash.now[:alert] = 'Please check for form errors.'
      render :edit
    end
  end

  def create_test
    respond_to do |f|
      f.js do
        @outcome_measure_test = @outcome_measure.tests.new(outcome_measure_test_params)
        if @outcome_measure_test.save
          flash[:notice] = 'The test has been successfully recorded.'
        end
      end
    end
  end

  def edit_test
    @outcome_measure_test = @outcome_measure.tests.find(params[:test_id])

    respond_to do |f|
      f.js
    end
  end

  def update_test
    respond_to do |f|
      f.js do
        @outcome_measure_test = @outcome_measure.tests.find(params[:test_id])
        if @outcome_measure_test.update(outcome_measure_test_params)
          flash[:notice] = 'The test has been successfully updated.'
        end
      end
    end
  end

  def delete_test
    test = @outcome_measure.tests.find(params[:test_id])
    test.destroy

    redirect_to patient_outcome_measure_url(@patient, @outcome_measure),
                  notice: 'The test has been successfully deleted.'
  end

  def send_to_patient
    OutcomeMeasureMailer.send_to_patient(@outcome_measure).deliver_later
    head :no_content
  end

  private

  def find_patient
    @patient = current_business.patients.find(params[:patient_id])
  end

  def outcome_measure
    @outcome_measure = @patient.outcome_measures.find(params[:id])
  end

  def create_outcome_measure_params
    params.require(:outcome_measure).permit(
      :practitioner_id,
      :outcome_measure_type_id
    )
  end

  def update_outcome_measure_params
    params.require(:outcome_measure).permit(
      :practitioner_id,
      :outcome_measure_type_id
    )
  end

  def outcome_measure_test_params
    params.require(:outcome_measure_test).permit(
      :result,
      :date_performed
    )
  end
end
