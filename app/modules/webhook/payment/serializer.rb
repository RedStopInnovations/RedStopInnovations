module Webhook
  module Payment
    class Serializer

      attr_reader :payment

      def initialize(payment)
        @payment = payment
      end

      def as_json(options = {})
        attrs = payment.attributes.symbolize_keys.slice(
          :id,
          :payment_date,
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
        )
        attrs[:stripe] = payment.stripe_charge_amount.to_f
        attrs[:total_amount] = payment.amount.to_f

        attrs[:patient] = Webhook::Patient::Serializer.new(payment.patient).as_json

        if payment.invoice
          attrs[:invoice] = Webhook::Invoice::Serializer.new(payment.invoice).as_json({relations: false})
        end

        attrs
      end
    end
  end
end