class ScheduleSendPaymentRemittanceService
  def call(invoice, trigger_payment)
    business = invoice.business
    payment_remittance_com_template = business.get_communication_template(CommunicationTemplate::TEMPLATE_ID_INVOICE_PAYMENT_REMITTANCE)

    if payment_remittance_com_template && payment_remittance_com_template.enabled?
      enabled_remittance_billable_item_ids = payment_remittance_com_template.settings['billable_item_ids'].presence || []

      if invoice.paid? && (enabled_remittance_billable_item_ids.blank? || invoice.items.billable_item.pluck(:invoiceable_id).any? { |bi_id| enabled_remittance_billable_item_ids.include?(bi_id) })
        SendPaymentRemittanceWorker.perform_async(invoice.id, trigger_payment.id)
      end
    end
  end
end