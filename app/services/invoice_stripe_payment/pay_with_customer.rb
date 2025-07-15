module InvoiceStripePayment
  class PayWithCustomer
    attr_reader :business, :invoice, :patient

    def call(business, invoice, payment)
      @business = business
      @invoice = invoice
      @patient = invoice.patient

      result = OpenStruct.new

      error = nil

      if !business.stripe_payment_available?
        error = 'Stripe payment is not available for your company account'
      end

      if patient.stripe_customer.nil?
        error = 'No payment method available for the client'
      end

      if error.nil?
        begin
          charge = create_charge
          result.charge = charge
          paid_amount = (charge.amount.to_f / 100)

          payment = build_payment if payment.nil?
          ApplicationRecord.transaction do
            payment.assign_attributes(
              stripe_charge_id: charge.id,
              stripe_charge_amount: paid_amount
            )
            payment.save!

            PaymentAllocation.create!(
              payment: payment,
              invoice: invoice,
              amount: paid_amount
            )
            invoice.reload
            invoice.update_outstanding_amount
          end

          ScheduleSendPaymentRemittanceService.new.call(invoice, payment)

          result.payment = payment
          result.success = true

        rescue Stripe::CardError => e
          result.success = false
          result.error = "Card error: #{ e.message }"
        rescue Stripe::StripeError => e
          result.success = false
          result.error = "An server error has ocurred."
          Sentry.capture_exception(e)
        end

      else
        result.success = false
        result.error = error
      end

      result
    end

    private


    def create_charge
      charge = Stripe::Charge.create(
        {
          amount: (invoice.outstanding * 100).to_i,
          currency: business.currency,
          customer: patient.stripe_customer.stripe_customer_id,
          description: "Payment for invoice ##{ invoice.invoice_number }",
          metadata: build_charge_metadata
        },
        stripe_account: business.stripe_account.account_id
      )
    end

    def build_payment
      Payment.new(
        business: business,
        patient: invoice.patient,
        payment_date: Date.today,
        editable: false
      )
    end

    def build_charge_metadata
      {
        Invoice: "#{invoice.invoice_number}",
        Patient: patient.full_name,
        Practitioner: invoice.practitioner.try(:full_name)
      }
    end
  end
end
