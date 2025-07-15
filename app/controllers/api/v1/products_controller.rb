module Api
  module V1
    class ProductsController < V1::BaseController
      before_action :find_product, only: [:show]

      def index
        products = current_business.
          products.
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: products,
               meta: pagination_meta(products)
      end

      def show
        render jsonapi: @product,
               include: [:tax]
      end

      private

      def find_product
        @product = current_business.products.find(params[:id])
      end
    end
  end
end
