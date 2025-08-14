module Api
  module V1
    class TreatmentNotesController < V1::BaseController
      before_action :find_treatment_note, only: [:show]

      def index
        treatment_notes = current_business.
          treatment_notes.
          includes(:patient, :author, :appointment).
          order(id: :asc).
          ransack(jsonapi_filter_params).
          result.
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: treatment_notes,
               include: [:patient, :author, :appointment],
               meta: pagination_meta(treatment_notes)
      end

      def show
        render jsonapi: @treatment_note,
               include: [:patient, :author, :appointment]
      end

      def poll
        treatment = current_business.treatment_notes
                               .order(id: :desc)
                               .first
        result = []
        result << Webhook::TreatmentNote::Serializer.new(treatment).as_json if treatment
        render json: result
      end

      private

      def find_treatment_note
        @treatment_note = current_business.treatment_notes.find(params[:id])
      end

      def jsonapi_whitelist_filter_params
        [
          :id_eq,

          :name_eq,
          :name_cont,

          :patient_id_eq,

          :status_eq,

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
