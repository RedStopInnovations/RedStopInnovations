module Api
  module V1
    class InvoiceSerializer < BaseSerializer
      type 'invoices'

      attributes :invoice_number,
                 :issue_date,
                 :amount,
                 :outstanding,
                 :deleted_at,
                 :updated_at,
                 :created_at

      attribute :outstanding do
        @object.outstanding.to_f
      end

      attribute :amount do
        @object.amount.to_f
      end

      belongs_to :patient do
        link :self do
          @url_helpers.api_v1_patient_url(@object.patient_id)
        end
      end

      has_many :items do
        link :self do
          @url_helpers.api_v1_invoice_invoice_items_url(@object.id)
        end
      end

      link :self do
        @url_helpers.api_v1_invoice_url(@object.id)
      end
    end
  end
end
