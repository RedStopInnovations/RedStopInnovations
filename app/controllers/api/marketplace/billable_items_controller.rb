module Api
  module Marketplace
    class BillableItemsController < Api::Marketplace::BaseController
      def index
        @billable_items = BillableItem.
          within_marketplace(current_marketplace.id).
          includes(:business)

        render(
          json: {
            billable_items: @billable_items.map do |bi|
              Api::Marketplace::BillableItemSerializer.new(bi)
            end
          }
        )
      end
    end
  end
end
