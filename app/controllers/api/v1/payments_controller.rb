module Api
  module V1
    class PaymentsController < V1::BaseController
      before_action :find_payment, only: [:show]

      def index
        payments = current_business.
          payments.
          includes(:patient).
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: payments,
               meta: pagination_meta(payments)
      end

      def show
        render jsonapi: @payment,
               include: [:patient, :invoice]
      end

      def poll
        payment = current_business.payments
                                  .order(id: :desc)
                                  .first
        result = []
        result << Webhook::Payment::Serializer.new(payment).as_json if payment
        render json: result
      end

      private

      def find_payment
        @payment = current_business.payments.find(params[:id])
      end
    end
  end
end
