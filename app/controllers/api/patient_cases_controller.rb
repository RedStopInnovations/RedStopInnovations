module Api
  class PatientCasesController < BaseController
    def show
      @patient_case = current_business.patient_cases.find(params[:id])
    end
  end
end
