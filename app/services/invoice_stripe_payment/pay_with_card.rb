module InvoiceStripePayment
  class PayWithCard
    attr_reader :business, :invoice, :patient, :stripe_token

    def call(business, invoice, stripe_token)
      @business = business
      @invoice = invoice
      @patient = invoice.patient
      @stripe_token = stripe_token

      result = OpenStruct.new

      begin
        charge = create_charge(stripe_token)
        result.charge = charge
        paid_amount = (charge.amount.to_f / 100)

        payment = build_payment
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
      end

      result
    end

    private

    def create_charge(token)
      Stripe::Charge.create(
        {
          amount: (invoice.outstanding * 100).to_i,
          currency: business.currency,
          source: token,
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
        editable: false # We dont allow edit payment made via Stripe to Medipass
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
