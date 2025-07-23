class BulkSendOutstandingInvoiceReminderService
  attr_reader :business, :invoice_ids, :author

  # @param business ::Business business
  # @param invoice_ids Array
  # @param author ::User
  def call(business, invoice_ids, author)
    @business = business
    @invoice_ids = invoice_ids
    @author = author

    invoices = business.invoices.includes(:patient, :invoice_to_contact).where(id: invoice_ids).to_a
    now = Time.current

    invoices.each do |invoice|
      patient = invoice.patient
      invoice_outstanding_reminder_info = invoice.outstanding_reminder || {}

      if invoice.invoice_to_contact && invoice.invoice_to_contact.email?
        contact = invoice.invoice_to_contact

        # Create communication log
        com = business.communications.create(
          message_type: Communication::TYPE_EMAIL,
          category: 'invoice_outstanding_reminder',
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
          last_tried_at: now,
          status: CommunicationDelivery::STATUS_SCHEDULED,
          provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
        )

        mail = InvoiceMailer.outstanding_invoice_reminder_to_contact(
          invoice,
          invoice.invoice_to_contact,
          sendgrid_delivery_tracking_id: com_delivery.tracking_id
        )

        mail.deliver_later
        com.update_column :message, mail.html_part.body.raw_source

        invoice_outstanding_reminder_info['last_send_at'] = Time.current.to_i
      else
        if patient.email? && patient.reminder_enable?
          com = business.communications.create!(
            message_type: Communication::TYPE_EMAIL,
            linked_patient_id: patient.id,
            recipient: patient,
            category: 'invoice_outstanding_reminder',
            message: nil,
            source: invoice,
            direction: Communication::DIRECTION_OUTBOUND
          )

          com_delivery = CommunicationDelivery.create!(
            communication_id: com.id,
            recipient: patient.email,
            tracking_id: SecureRandom.base58(32),
            last_tried_at: now,
            status: CommunicationDelivery::STATUS_SCHEDULED,
            provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
          )

          mail = InvoiceMailer.outstanding_invoice_reminder(
            invoice, sendgrid_delivery_tracking_id: com_delivery.tracking_id
          )

          mail.deliver_later
          com.update_column :message, mail.html_part.body.raw_source

          invoice_outstanding_reminder_info['last_send_at'] = Time.current.to_i
        end
      end

      invoice.update_column :outstanding_reminder, invoice_outstanding_reminder_info
    end
  end
end