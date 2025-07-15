module Api
  module V1
    class InvoiceItemsController < V1::BaseController
      before_action :find_invoice

      def index
        invoice_items = @invoice.items.order(id: :asc)

        render jsonapi: invoice_items,
               links: {
                 self: api_v1_invoice_invoice_items_url(@invoice)
               }
      end

      def show
        invoice_item = @invoice.items.find(params[:id])
        render jsonapi: invoice_item
      end

      private

      def find_invoice
        @invoice = current_business.invoices.find(params[:invoice_id])
      end
    end
  end
end
