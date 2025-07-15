module Api
  module V1
    class InvoicesController < V1::BaseController
      before_action :find_invoice, only: [:show]

      def index
        invoices = current_business.
          invoices.
          includes(:patient, items: [:invoiceable]).
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: invoices,
               include: [:patient, :items],
               meta: pagination_meta(invoices)

      end

      def show
        render jsonapi: @invoice,
               include: [:patient, :items]
      end

      def poll
        invoice = current_business.invoices
                                  .order(id: :desc)
                                  .first
        result = []
        result << Webhook::Invoice::Serializer.new(invoice).as_json if invoice
        render json: result
      end

      private

      def find_invoice
        @invoice = current_business.invoices.find(params[:id])
      end
    end
  end
end
