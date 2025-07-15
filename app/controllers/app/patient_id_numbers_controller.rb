module App
  class PatientIdNumbersController < ApplicationController
    include HasABusiness

    before_action :set_patient
    before_action :set_patient_number, only: [:edit, :update, :destroy]

    def index
      @patient_numbers = @patient.id_numbers.order(id_number: :desc)
    end

    def new
      @patient_number = PatientIdNumber.new
    end

    def edit
    end

    def create
      @patient_number = @patient.id_numbers.new patient_number_params
      if @patient_number.save
        redirect_to app_patient_id_numbers_url,
          notice: "Id numbers has been created"
      else
        flash.now[:alert] = 'Failed to create id. Please check for form errors.'
        render :new
      end
    end

    def update
      @patient_number.assign_attributes patient_number_params

      if @patient_number.save
        redirect_to app_patient_id_numbers_url,
          notice: "Id numbers has been update"
      else
        flash.now[:alert] = 'Failed to update id. Please check for form errors.'
        render :edit
      end
    end

    def destroy
      @patient_number.destroy
      redirect_to app_patient_id_numbers_url,
        notice: "Id numbers has been removed"
    end

    private
    def set_patient
      @patient = current_business.patients.find(params[:patient_id])
    end

    def set_patient_number
      @patient_number = @patient.id_numbers.find params[:id]
    end

    def patient_number_params
      params.require(:patient_id_number).permit(:contact_id, :id_number)
    end
  end
end
