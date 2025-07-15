module Api
  class ProductsController < BaseController
    def index
      @products = current_business
        .products
        .not_deleted
        .order(name: :asc)
        .includes(:tax)
    end

    def show
      @product = current_business.products.find(params[:id])
    end
  end
end
