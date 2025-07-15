module Webhook
  module InvoiceItem
    class Serializer

      attr_reader :item

      def initialize(item)
        @item = item
      end

      def as_json(options = {})
        attrs = item.attributes.symbolize_keys.slice(
          :id,
          :quantity,
          :unit_price,
          :description,
          :item_code,
          :tax_rate,
          :amount
        )

        attrs[:name] = item.unit_name
        attrs[:type] = item.invoiceable_type
        attrs[:unit_price] = item.unit_price.to_f
        attrs[:amount] = item.amount.to_f

        attrs
      end
    end
  end
end