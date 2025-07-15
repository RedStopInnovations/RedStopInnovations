module Api
  class AppointmentTypesController < BaseController
    def index
      @appointment_types = current_business
        .appointment_types
        .order(name: :asc)
        .includes(:billable_items)
    end

    def show
      @appointment_type = current_business.appointment_types.find(params[:id])
    end
  end
end
