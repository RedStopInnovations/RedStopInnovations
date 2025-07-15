module Api
  module V1
    class PaymentSerializer < BaseSerializer
      type 'payments'

      attributes :payment_date,
                 :eftpos,
                 :hicaps,
                 :cash,
                 :medicare,
                 :workcover,
                 :dva,
                 :direct_deposit,
                 :stripe,
                 :other,
                 :created_at,
                 :updated_at,
                 :deleted_at

      attribute :stripe do
        @object.stripe_charge_amount
      end

      attribute :total_amount do
        @object.amount
      end

      belongs_to :patient do
        link :self do
          @url_helpers.api_v1_patient_url(@object.patient_id)
        end
      end

      belongs_to :invoice do
        if @object.invoice_id?
          link :self do
            @url_helpers.api_v1_invoice_url(@object.invoice_id)
          end
        end
      end

      link :self do
        @url_helpers.api_v1_payment_url(@object.id)
      end

      meta do
        {
          applied_invoice: @object.invoice_id?
        }
      end
    end
  end
end
