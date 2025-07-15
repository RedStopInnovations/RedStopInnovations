# @TODO: not used?
module Reports
  class BulkBillClaimsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :reports
    end

    def index
      @claims = InvoiceClaim.bulk_bill.includes(:invoice).page(params[:page])
    end

    def show
      @claim = InvoiceClaim.bulk_bill.find(params[:id])
    end
  end
end
