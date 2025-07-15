module Api
  module V1
    class AppointmentsController < V1::BaseController
      before_action :find_appointment, only: [:show]

      def index
        appointments = current_business.
          appointments.
          order(id: :asc).
          includes(:practitioner, :patient, :appointment_type, :availability, :arrival).
          ransack(jsonapi_filter_params).
          result.
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: appointments,
               include: [:patient, :appointment_type, :availability, :practitioner, :appointment_arrival],
               meta: pagination_meta(appointments)
      end

      def poll
        appointment = current_business.
            appointments.
            includes(:patient, :practitioner, :appointment_type).
            order(id: :desc).
            first
        result = []
        result << Webhook::Appointment::Serializer.new(appointment).as_json if appointment
        render json: result
      end

      def show
        render jsonapi: @appointment,
                include: [:patient, :appointment_type, :availability, :practitioner, :appointment_arrival]
      end

      private

      def find_appointment
        @appointment = current_business.appointments.find(params[:id])
      end

      def jsonapi_whitelist_filter_params
        [
          :id_eq,
          :patient_id_eq,
          :appointment_type_id_eq,
          :start_time_lt,
          :start_time_lteq,
          :start_time_gt,
          :start_time_gteq,
        ]
      end
    end
  end
end
