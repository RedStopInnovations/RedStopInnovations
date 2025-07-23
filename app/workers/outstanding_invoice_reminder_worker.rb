class OutstandingInvoiceReminderWorker
  include Sidekiq::Worker

  sidekiq_options retry: 2

  def perform(invoice_id)
    invoice = Invoice.find_by(id: invoice_id)
    return if invoice.nil?

    invoice_outstanding_reminder_info = invoice.outstanding_reminder || {}

    return if invoice.paid? || invoice.deleted_at?

    return unless invoice_outstanding_reminder_info['enable'] == true

    @invoice = invoice
    business = invoice.business
    template = business.get_communication_template(CommunicationTemplate::TEMPLATE_ID_OUTSTANDING_INVOICE_REMINDER)
    return unless template.enabled?

    @reminder_settings = template.settings || {}

    current_reminders_count = invoice_outstanding_reminder_info['reminders_count'].to_i

    # Check if max repeat occurences reached
    if @reminder_settings['repeat'] && @reminder_settings['repeat_occurences'].present?
      return if (current_reminders_count - 1) >= @reminder_settings['repeat_occurences']
    end

    now = Time.current
    patient = invoice.patient

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

      mail.deliver_now
      com.update_column :message, mail.html_part.body.raw_source

      invoice_outstanding_reminder_info['reminders_count'] = current_reminders_count + 1
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

        mail.deliver_now
        com.update_column :message, mail.html_part.body.raw_source

        invoice_outstanding_reminder_info['reminders_count'] = current_reminders_count + 1
        invoice_outstanding_reminder_info['last_send_at'] = Time.current.to_i
      end
    end

    if @reminder_settings['repeat'] == true
      if (!@reminder_settings['repeat_occurences'].present? || ((invoice_outstanding_reminder_info['reminders_count'] - 1) < @reminder_settings['repeat_occurences']))
        next_reminder_at = now.advance(days: @reminder_settings['repeat_interval_days'])
        jid = OutstandingInvoiceReminderWorker.perform_at(next_reminder_at, @invoice.id)
        invoice_outstanding_reminder_info['scheduled_job_id'] = jid
        invoice_outstanding_reminder_info['scheduled_job_perform_at'] = next_reminder_at.to_i
      end
    end

    invoice.update_column :outstanding_reminder, invoice_outstanding_reminder_info
  end
end
