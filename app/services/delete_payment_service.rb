class DeletePaymentService
  attr_reader :business, :payment

  def call(business, payment, author)
    @business = business
    @payment = payment

    ApplicationRecord.transaction do
      allocated_invoice_ids = payment.payment_allocations.pluck(:invoice_id)
      PaymentAllocation.where(payment_id: payment.id).delete_all
      payment.destroy_by_author(author)

      Invoice.where(id: allocated_invoice_ids).each(&:update_outstanding_amount)
    end
  end
end
