class CreatePaymentService
  attr_reader :business, :form_request

  # @param business ::Business
  # @param form_request ::CreatePaymentForm
  def call(business, form_request)
    result = OpenStruct.new

    @business = business
    @form_request = form_request
    payment = build_payment

    needed_update_invoice_ids = []
    ActiveRecord::Base.transaction do
      payment.save!(validate: false)

      # Create allocations
      form_request.payment_allocations.each do |alloc_attrs|
        PaymentAllocation.create!(
          payment_id: payment.id,
          invoice_id: alloc_attrs.invoice_id,
          amount: alloc_attrs.amount
        )
        needed_update_invoice_ids << alloc_attrs.invoice_id
      end

      Invoice.where(id: needed_update_invoice_ids).each do |inv|
        inv.update_outstanding_amount
      end
    end

    if payment.persisted?
      ::Webhook::Worker.perform_later(payment.id, WebhookSubscription::PAYMENT_CREATED)
      Invoice.where(id: needed_update_invoice_ids).each do |invoice|
        ScheduleSendPaymentRemittanceService.new.call(invoice, payment) if invoice.paid?
      end
    end

    result.payment = payment
    result
  end

  private

  def build_payment
    payment = Payment.new(
      form_request.attributes.slice(
        :cash,
        :medicare,
        :workcover,
        :dva,
        :direct_deposit,
        :cheque,
        :other,
        :payment_date,
        :patient_id
      )
    )
    payment.business = business
    payment
  end
end
