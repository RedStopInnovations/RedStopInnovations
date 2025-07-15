module Api
  module V1
    class InvoiceItemSerializer < BaseSerializer
      type 'invoice_items'

      attribute :name do
        @object.unit_name
      end

      attribute :type do
        @object.invoiceable_type
      end

      attributes :description,
                 :item_code,
                 :tax_rate,
                 :amount

      attribute :amount do
        @object.amount.to_f
      end

      attribute :unit_price do
        @object.unit_price.to_f
      end

      attribute :quantity do
        @object.quantity.to_f
      end

      link :self do
        @url_helpers.api_v1_invoice_invoice_item_url(@object.invoice_id, @object.id)
      end
    end
  end
end
