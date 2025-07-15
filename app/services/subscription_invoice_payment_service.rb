class SubscriptionInvoicePaymentService

  class InvoiceNotPayableError < StandardError; end
  class PaymentProcessError < StandardError; end

  attr_reader :business, :business_invoice

  def call(business_invoice)
    @business_invoice = business_invoice
    @business = business_invoice.business
    result = OpenStruct.new(success: false)

    if business_invoice.amount.zero?
      raise InvoiceNotPayableError, 'Invoice has zero amount'
    end

    if business.subscription.stripe_customer_id.blank?
      raise InvoiceNotPayableError, 'Subscription\'s credit card not added'
    end

    if business_invoice.amount < 0.5
      raise InvoiceNotPayableError, 'Invoice amount is too small. Minimum is $0.5'
    end

    begin
      stripe_customer_id = business.subscription.stripe_customer_id
      customer = Stripe::Customer.retrieve(stripe_customer_id)

      stripe_charge = Stripe::Charge.create(
        customer: customer.id,
        amount: (business_invoice.amount * 100).to_i,
        description: "Payment for subscription. Invoice ##{business_invoice.invoice_number}.",
        currency: 'aud',
        metadata: {
          business_id: business.id,
          business_name: business.name,
          business_email: business.email.presence,
          business_phone: business.phone.presence,
        }
      )

      if stripe_charge.paid
        subscription_payment = SubscriptionPayment.new(
          payment_date: Time.current,
          payment_type: 'Credit card',
          amount: business_invoice.amount,
          stripe_charge_id: stripe_charge.id,
          business_id: business_invoice.business_id,
          invoice_id: business_invoice.id
        )

        ActiveRecord::Base.transaction do
          business_invoice.update_column :payment_status, 'paid'
          subscription_payment.save!(validate: false)
          result.success = true
        end

        if subscription_payment.persisted?
          BusinessInvoiceMailer.business_invoice_mail(business_invoice, business.subscription).deliver_later
          business_invoice.update_column :last_sent_at, Time.current
        end

      else
        result.success = false
      end
    rescue => e
      case e
      when Stripe::StripeError
        raise PaymentProcessError, e.message
      else
        raise e
      end
    end

    result
  end

  private

  def build_subscription_payment(stripe_charge_id)
    payment = SubscriptionPayment.new(
      payment_date: Time.current,
      amount: business_invoice.amount,
      stripe_charge_id: stripe_charge_id,
      business_id: business_invoice.business_id
    )
    payment.save!(validate: false)
    payment
  end
end
