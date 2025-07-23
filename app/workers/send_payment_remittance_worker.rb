class SendPaymentRemittanceWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  def perform(invoice_id, trigger_payment_id)
    invoice = Invoice.find_by(id: invoice_id)
    trigger_payment = Payment.find_by(id: trigger_payment_id)
    business = invoice.business
    patient = invoice.patient

    if invoice.nil? || trigger_payment.nil? || !invoice.paid?
      return
    end

    if !business.communication_template_enabled?(CommunicationTemplate::TEMPLATE_ID_INVOICE_PAYMENT_REMITTANCE)
      return
    end

    if invoice.invoice_to_contact && invoice.invoice_to_contact.email?
      contact = invoice.invoice_to_contact

      com = business.communications.create(
        message_type: Communication::TYPE_EMAIL,
        category: 'invoice_payment_remittance',
        linked_patient_id: patient.id,
        recipient: contact,
        message: nil,
        source: invoice,
        direction: Communication::DIRECTION_OUTBOUND
      )

      com_delivery = CommunicationDelivery.create!(
        communication_id: com.id,
        recipient: contact.email,
        tracking_id: SecureRandom.base58(32),
        last_tried_at: Time.current,
        status: CommunicationDelivery::STATUS_SCHEDULED,
        provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
      )

      mail = InvoiceMailer.payment_remittance_to_contact(
        invoice,
        trigger_payment,
        contact,
        sendgrid_delivery_tracking_id: com_delivery.tracking_id
      )

      mail.deliver_now!
      com.update_column :message, mail.html_part.body.raw_source
    else
      if patient.email? && patient.reminder_enable?
        com = business.communications.create!(
          message_type: Communication::TYPE_EMAIL,
          category: 'invoice_payment_remittance',
          linked_patient_id: patient.id,
          recipient: patient,
          message: nil,
          source: invoice,
          direction: Communication::DIRECTION_OUTBOUND
        )

        com_delivery = CommunicationDelivery.create!(
          communication_id: com.id,
          recipient: patient.email,
          tracking_id: SecureRandom.base58(32),
          last_tried_at: Time.current,
          status: CommunicationDelivery::STATUS_SCHEDULED,
          provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
        )

        mail = InvoiceMailer.payment_remittance(
          invoice,
          trigger_payment,
          sendgrid_delivery_tracking_id: com_delivery.tracking_id
        )

        mail.deliver_now!
        com.update_column :message, mail.html_part.body.raw_source
      end
    end
  end
end