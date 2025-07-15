module Api
  module V1
    class PatientsController < V1::BaseController
      before_action :find_patient, only: [:show]

      def index
        patients = current_business.
          patients.
          order(id: :asc).
          ransack(jsonapi_filter_params).
          result.
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: patients,
               meta: pagination_meta(patients)
      end

      def show
        render jsonapi: @patient
      end

      def poll
        patient = current_business.patients
                                      .order(id: :desc)
                                      .first
        result = []
        result << Webhook::Patient::Serializer.new(patient).as_json if patient
        render json: result
      end

      def appointments
        @patient = current_business.patients.find(params[:patient_id])

        appointments = @patient.
          appointments.
          includes(:practitioner, :appointment_type, :availability, :arrival).
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: appointments,
               include: [:appointment_type, :practitioner, :appointment_arrival],
               meta: pagination_meta(appointments)
      end

      def contact_associations
        @patient = current_business.patients.find(params[:patient_id])

        render jsonapi: @patient.patient_contacts.order(id: :desc)
      end

      private

      def find_patient
        @patient = current_business.patients.find(params[:id])
      end

      def jsonapi_whitelist_filter_params
        [
          :id_eq,

          :first_name_eq,
          :first_name_cont,

          :last_name_eq,
          :last_name_cont,

          :full_name_eq,
          :full_name_cont,

          :dob_eq,

          :email_cont,
          :phone_cont,
          :mobile_cont,

          :city_eq,
          :state_eq,
          :postcode_eq,

          :created_at_lt,
          :created_at_lteq,
          :created_at_gt,
          :created_at_gteq,

          :updated_at_lt,
          :updated_at_lteq,
          :updated_at_gt,
          :updated_at_gteq
        ]
      end
    end
  end
end
