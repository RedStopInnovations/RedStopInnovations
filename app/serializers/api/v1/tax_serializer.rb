module Api
  module V1
    class TaxSerializer < BaseSerializer
      type 'taxes'

      attributes :name, :rate

      link :self do
        @url_helpers.api_v1_tax_url(@object.id)
      end
    end
  end
end
