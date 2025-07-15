class ChargeSubscriptionInvoiceJob < ApplicationJob
  def perform(invoice_id)
    invoice = BusinessInvoice.find_by(id: invoice_id)

    if invoice && invoice.pending?
      business = invoice.business
      subscription = business.subscription

      if !subscription.on_trial? && subscription.credit_card_added?
        begin
          SubscriptionInvoicePaymentService.new.call(invoice)
        rescue => e
          unless e.is_a?(Stripe::CardError)
            Sentry.capture_exception(e)
          end
        end
      end
    end
  end
end
