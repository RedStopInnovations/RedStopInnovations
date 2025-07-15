module Api
  module V1
    class PractitionersController < V1::BaseController
      before_action :find_practitioner, only: [:show]

      def index
        practitioners = current_business.
          practitioners.
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: practitioners,
               meta: pagination_meta(practitioners)
      end

      def show
        render jsonapi: @practitioner
      end

      private

      def find_practitioner
        @practitioner = current_business.practitioners.find(params[:id])
      end

      def practitioner_params
        # NOTE: update with 5.2
        # https://github.com/rails/rails/commit/e86524c0c5a26ceec92895c830d1355ae47a7034

        params.require(:data).permit(
          attributes: [
            :profession,
            :education,
            :summary,
            :ahpra,
            :medicare,
            :phone,
            :mobile,
            :website,
            :email,
            :address1,
            :address2,
            :city,
            :state,
            :postcode,
            :country
          ]
        ).tap do |whitelisted|
          whitelisted[:metadata] = params[:data][:attributes][:metadata]
          whitelisted.permit!
        end
      end

      def user_params
        # TODO: documented this for API?
        params.require(:data).permit(attributes: [
          :first_name, :last_name, :email, :timezone, :active
        ])
      end
    end
  end
end
