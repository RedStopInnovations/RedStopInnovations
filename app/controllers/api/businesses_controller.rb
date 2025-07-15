module Api
  class BusinessesController < BaseController
    def show
      @business = current_business
    end

    def info
      @business = current_business
      render :show
    end
  end
end
