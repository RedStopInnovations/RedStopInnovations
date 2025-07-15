module Api
  module V1
    class AppointmentTypesController < V1::BaseController
      before_action :find_appointment_type, only: [:show]

      def index
        appointment_types = current_business.
          appointment_types.
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: appointment_types,
               meta: pagination_meta(appointment_types)
      end

      def show
        render jsonapi: @appointment_type
      end

      private

      def find_appointment_type
        @appointment_type = current_business.appointment_types.find(params[:id])
      end
    end
  end
end
