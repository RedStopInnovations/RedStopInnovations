class UpdatePaymentService
  attr_reader :business, :payment, :form_request

  # @param business ::Business
  # @param payment ::Payment
  # @param form_request ::UpdatePaymentForm
  def call(business, payment, form_request)
    result = OpenStruct.new

    @business = business
    @form_request = form_request
    @payment = payment

    assign_payment_attributes

    prev_allocated_inv_ids = payment.payment_allocations.pluck(:invoice_id)
    new_allocated_inv_ids = []
    keep_allocated_inv_ids = []

    needed_send_remittance_inv_ids = []

    ActiveRecord::Base.transaction do
      payment.save!(validate: false)

      form_request.payment_allocations.each do |alloc_attrs|
        invoice_id = alloc_attrs.invoice_id

        invoice = business.invoices.with_deleted.find_by(id: invoice_id)

        if prev_allocated_inv_ids.include?(alloc_attrs.invoice_id)
          was_outstanding = (invoice.amount - invoice.payment_allocations.sum(:amount)) > 0

          allocation = PaymentAllocation.find_or_initialize_by(
            payment_id: payment.id,
            invoice_id: invoice_id
          )
          allocation.amount = alloc_attrs.amount
          allocation.save!(validate: false)
          keep_allocated_inv_ids << invoice_id

          invoice.payment_allocations.reload

          # Check if fully paid after this change
          now_paid = invoice.amount <= invoice.payment_allocations.sum(:amount)
          if was_outstanding && now_paid
            needed_send_remittance_inv_ids << invoice_id
          end
        else
          allocation = PaymentAllocation.new(
            payment_id: payment.id,
            invoice_id: invoice_id,
            amount: alloc_attrs.amount
          )
          allocation.save!(validate: false)
          new_allocated_inv_ids << invoice_id

          if invoice.payment_allocations.sum(:amount) >= invoice.amount
            needed_send_remittance_inv_ids << invoice_id
          end
        end
      end

      # Check to deleted allocations
      delete_allocated_invoice_ids = prev_allocated_inv_ids - keep_allocated_inv_ids

      needed_update_inv_ids = (
        prev_allocated_inv_ids +
        delete_allocated_invoice_ids +
        keep_allocated_inv_ids +
        new_allocated_inv_ids
      ).uniq

      unless delete_allocated_invoice_ids.empty?
        # @TODO: add this to audit log?
        PaymentAllocation.where(
          payment_id: payment.id,
          invoice_id: delete_allocated_invoice_ids
        ).delete_all
      end

      Invoice.where(id: needed_update_inv_ids).each do |inv|
        inv.update_outstanding_amount
      end
    end

    Invoice.where(id: needed_send_remittance_inv_ids).each do |invoice|
      ScheduleSendPaymentRemittanceService.new.call(invoice, payment)
    end

    result.payment = payment
    result
  end

  private

  def assign_payment_attributes
    payment.assign_attributes(
      form_request.attributes.slice(
        :cash,
        :medicare,
        :workcover,
        :dva,
        :direct_deposit,
        :cheque,
        :other,
        :payment_date
      )
    )
  end
end
