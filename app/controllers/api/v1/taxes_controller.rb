module Api
  module V1
    class TaxesController < V1::BaseController
      before_action :find_tax, only: [:show]

      def index
        taxes = current_business.
          taxes.
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: taxes,
               meta: pagination_meta(taxes)
      end

      def show
        render jsonapi: @tax
      end

      private

      def find_tax
        @tax = current_business.taxes.find(params[:id])
      end
    end
  end
end
