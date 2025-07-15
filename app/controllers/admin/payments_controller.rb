module Admin
  class PaymentsController < BaseController

    def index
      @payments = Payment.includes(:patient, :invoice, :business).
        order("payment_date DESC").
        page(params[:page])
    end

    def show
      @payment = Payment.find(params[:id])
    end
  end
end
