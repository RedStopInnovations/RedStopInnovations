module Api
  module Marketplace
    class BillableItemSerializer
      attr_reader :billable_item

      def initialize(billable_item)
        @billable_item = billable_item
      end

      def as_json(_options = {})
        data = billable_item.attributes.symbolize_keys.slice(
          :id, :name, :description, :item_number,
          :updated_at, :created_at
        )
        data[:price] = billable_item.price.to_f
        data[:business] = Api::Marketplace::BusinessSerializer.new(billable_item.business)
        data
      end
    end
  end
end
