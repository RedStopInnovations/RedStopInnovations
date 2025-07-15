module Letter
  module Embeddable
    class Invoice < Base
      VARIABLES = [
        'Invoice.Number',
        'Invoice.OnlinePaymentURL'
      ]

      # @param invoice ::Invoice
      def initialize(invoice)
        @invoice = invoice
        super map_attributes
      end

      private

      def map_attributes
        map = {}
        map['Invoice.Number'] = @invoice.invoice_number
        map['Invoice.OnlinePaymentURL'] =
          Rails.application.routes.url_helpers.public_invoice_payment_url(
            token: @invoice.public_token? ? @invoice.public_token : @invoice.id
          )
        map
      end
    end
  end
end
