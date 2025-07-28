module Api
  module V1
    class BillableItemSerializer < BaseSerializer
      type 'billable_items'

      attributes :name,
                 :description,
                 :item_number,
                 :price,
                 :created_at,
                 :updated_at

      belongs_to :tax do
        if @object.tax_id?
          link :self do
            @url_helpers.api_v1_tax_url(@object.tax_id)
          end
        end
      end

      attribute :price do
        @object.price.to_f
      end

      link :self do
        @url_helpers.api_v1_billable_item_url(@object.id)
      end
    end
  end
end
