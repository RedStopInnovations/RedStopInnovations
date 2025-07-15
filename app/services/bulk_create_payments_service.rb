class BulkCreatePaymentsService
  attr_reader :business, :form_request, :author

  # @param business ::Business business
  # @param form_request BulkCreatePaymentsForm
  # @param author ::User
  def call(business, form_request, author)
    @business = business
    @form_request = form_request
    @author = author

    created_payments = []

    Payment.transaction do
      form_request.payments.each do |payment_data|
        invoice = business.invoices.find_by!(id: payment_data.invoice_id)
        invoice_outstanding_amount = invoice.amount

        payment = Payment.new(
          business_id: business.id,
          patient_id: invoice.patient_id,
          payment_date: payment_data.payment_date,
          payment_method: payment_data.payment_method,
          amount: invoice_outstanding_amount
        )

        case payment_data.payment_method
        when PaymentType::DIRECT_DEPOSIT
          payment.direct_deposit = invoice_outstanding_amount
        when PaymentType::CASH
          payment.cash = invoice_outstanding_amount
        when PaymentType::CHEQUE
          payment.cheque = invoice_outstanding_amount
        when PaymentType::WORKCOVER
          payment.workcover = invoice_outstanding_amount
        # when PaymentType::MEDICARE
        #   payment.medicare = invoice_outstanding_amount
        # when PaymentType::DVA
        #   payment.dva = invoice_outstanding_amount
        when PaymentType::OTHER
          payment.other = invoice_outstanding_amount
        else
          raise "Payment method #{payment_data.payment_method} is invalid"
        end

        payment.save!

        PaymentAllocation.create!(
          payment_id: payment.id,
          invoice_id: invoice.id,
          amount: invoice_outstanding_amount
        )

        invoice.update_columns(
          outstanding: 0,
          updated_at: Time.current
        )

        created_payments << payment
      end
    end

    created_payments.each do |payment|
      ::Webhook::Worker.perform_later(payment.id, WebhookSubscription::PAYMENT_CREATED)
      payment.invoices.each do |allocated_invoice|
        ScheduleSendPaymentRemittanceService.new.call(allocated_invoice, payment) if allocated_invoice.paid?
      end
    end

    created_payments
  end
end