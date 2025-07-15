module Api
  module V1
    class PatientAttachmentsController < V1::BaseController
      before_action :find_patient

      def index
        attachments = @patient.
          attachments.
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: attachments,
               meta: pagination_meta(attachments)
      end

      def show
        attachment = @patient.attachments.find(params[:id])

        render jsonapi: attachment
      end

      def create
        attachment = @patient.attachments.new create_attachment_params

        if attachment.save
          render jsonapi: attachment, status: 201
        else
          render jsonapi_errors: attachment.errors, status: 422
        end
      end

      private

      def find_patient
        @patient = current_business.patients.find(params[:patient_id])
      end

      def create_attachment_params
        params.permit(data: [attributes: [:description, :attachment]]).dig(:data, :attributes)
      end
    end
  end
end
