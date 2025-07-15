module Api
  module V1
    class BillableItemsController < V1::BaseController
      before_action :find_billable_item, only: [:show, :update, :destroy]

      def index
        billable_items = current_business.
          billable_items.
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: billable_items,
               meta: pagination_meta(billable_items)
      end

      def show
        render jsonapi: @billable_item,
               include: [:tax]
      end

      private

      def find_billable_item
        @billable_item = current_business.billable_items.find(params[:id])
      end
    end
  end
end
