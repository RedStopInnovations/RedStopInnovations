class CreateBusinessInvoiceWorker
  include Sidekiq::Worker

  def perform
    Subscription.
      where("billing_end < ?", Time.current).
      find_each do |subscription|
      begin

      # Create new invoice
      invoice = SubscriptionBillingService.new.create_subscription_invoice(subscription)

      # Renew billing cycle
      SubscriptionBillingService.new.renew_billing_cycle(subscription)

      if invoice
        # Send invoice
        if subscription.auto_send_invoice
          BusinessInvoiceMailer.business_invoice_mail(invoice, subscription).deliver_later
        end

        # Notify super admin
        if subscription.notify_new_invoice
          AdminMailer.new_subscription_invoice(invoice).deliver_later
        end

        # Schedule auto payment
        if subscription.auto_payment && subscription.credit_card_added?
          payment_delay_in_hours = subscription.auto_payment_delay.to_i
          ChargeSubscriptionInvoiceJob.set(wait_until: Time.current + payment_delay_in_hours.hours).perform_later(invoice.id)
        end
      end

      rescue => e
        Sentry.capture_exception e
      end
    end
  end
end
