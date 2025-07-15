module InvoiceStripePayment
  class PayMultiple
    attr_reader :business, :form_request, :patient

    # @param business Business
    # @param token    String The stripe token
    def call(business, form_request)
      @business = business
      @form_request = form_request
      @patient = Patient.find form_request.patient_id

      result = OpenStruct.new

      if !business.stripe_payment_available?
        result.success = false
        result.error = 'Stripe payment is not available for your company account'
      else
        begin
          if !form_request.use_current_card && form_request.save_card
            save_card_result = UpdatePatientCardService.new.call(
              business,
              patient,
              form_request.stripe_token
            )
            unless save_card_result.success
              raise 'Can not process the entered credit card info.'
            end
            patient.reload
          end

          charge = create_charge
          result.charge = charge
          paid_amount = (charge.amount.to_f / 100)

          payment = build_payment
          ApplicationRecord.transaction do
            payment.assign_attributes(
              stripe_charge_id: charge.id,
              stripe_charge_amount: paid_amount
            )
            payment.save!

            invoices.each do |invoice|
              PaymentAllocation.create!(
                payment: payment,
                invoice: invoice,
                amount: invoice.outstanding
              )
              invoice.reload
              invoice.update_outstanding_amount
            end
          end

          invoices.each do |invoice|
            ScheduleSendPaymentRemittanceService.new.call(invoice, payment)
          end

          result.payment = payment
          result.success = true

        rescue Stripe::CardError, Stripe::InvalidRequestError => e
          result.success = false
          result.error = e.message
        end
      end

      result
    end

    private

    def invoices
      @invoices ||= business.invoices.where(id: form_request.invoice_ids).to_a
    end

    def create_charge
      charge_amount = (invoices.sum(&:outstanding) * 100).to_i
      charge_description = "Payment for invoice#{'s' if invoices.size > 1} ##{ invoices.map(&:invoice_number).join(', ') }",

      if !form_request.use_current_card && !form_request.save_card
        charge = Stripe::Charge.create(
          {
            amount: charge_amount,
            currency: business.currency,
            source: form_request.stripe_token,
            description: charge_description,
            metadata: build_charge_metadata
          },
          stripe_account: business.stripe_account.account_id
        )
      else
        charge = Stripe::Charge.create(
          {
            amount: charge_amount,
            currency: business.currency,
            customer: patient.stripe_customer.stripe_customer_id,
            description: charge_description,
            metadata: build_charge_metadata
          },
          stripe_account: business.stripe_account.account_id
        )
      end

      charge
    end

    def build_payment
      Payment.new(
        business: business,
        patient: patient,
        payment_date: Date.today,
        editable: false
      )
    end

    def build_charge_metadata
      {
        Invoice: "#{invoices.map(&:invoice_number).join(', ')}",
        Patient: patient.full_name
      }
    end
  end
end
