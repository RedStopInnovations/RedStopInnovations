module Api
  module V1
    class BusinessesController < V1::BaseController
      def show
        render jsonapi: current_business
      end
    end
  end
end
