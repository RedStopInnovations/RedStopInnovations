module Api
  module V1
    class ProductSerializer < BaseSerializer
      type 'products'

      attributes :name,
                 :price,
                 :item_number,
                 :serial_number,
                 :supplier_name,
                 :supplier_phone,
                 :supplier_email,
                 :notes

      belongs_to :tax do
        if @object.tax_id?
          link :self do
            @url_helpers.api_v1_tax_url(@object.tax_id)
          end
        end
      end

      attribute :item_number do
        @object.item_code
      end

      attribute :price do
        @object.price.to_f
      end

      link :self do
        @url_helpers.api_v1_product_url(@object.id)
      end
    end
  end
end
