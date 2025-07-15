# @TODO: not used?
module Reports
  class DvaClaimsController < ApplicationController
    include HasABusiness

    def index
      @claims = InvoiceClaim.dva.includes(:invoice).page(params[:page])
    end

    def show
      @claim = InvoiceClaim.dva.find(params[:id])
    end
  end
end
