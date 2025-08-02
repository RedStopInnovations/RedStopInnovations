class SendInvoiceBatchJob < ApplicationJob
  def perform(invoice_batch_id, sender_user_id = nil)
    invoice_batch = InvoiceBatch.find(invoice_batch_id)
    business = invoice_batch.business
    sender = if sender_user_id
               User.find_by(id: sender_user_id)
             end

    invoice_batch.update(
      last_send_at: Time.current
    )

    invoice_batch.invoices.find_each do |invoice|
      unless invoice.paid? || invoice.deleted_at?
        SendInvoiceService.new.call(invoice, sender)
      end
    end
  end
end