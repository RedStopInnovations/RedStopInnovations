module Api
  module V1
    class AvailabilitiesController < V1::BaseController
      before_action :find_availability, only: [:show]

      def index
        availabilities = current_business.
          availabilities.
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: availabilities,
               include: [:appointments],
               meta: pagination_meta(availabilities)
      end

      def show
        render jsonapi: @availability,
               include: [:appointments, :contact]
      end

      def poll
        availability = current_business.availabilities
                                       .order(id: :desc)
                                       .first
        result = []
        result << Webhook::Availability::Serializer.new(availability).as_json if availability
        render json: result
      end

      private

      def find_availability
        @availability = current_business.availabilities.find(params[:id])
      end
    end
  end
end
