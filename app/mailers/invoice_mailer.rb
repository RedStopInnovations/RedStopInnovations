class InvoiceMailer < ApplicationMailer
  helper :application

  def invoice_mail(invoice)
    @invoice  = invoice
    @business = @invoice.business
    @patient  = invoice.patient
    @practitioner = @invoice.practitioner
    @template = @business.get_communication_template('send_invoice_pdf')
    embed_variables = [
      @business, @invoice, @patient
    ]
    unless @practitioner.nil?
      embed_variables << @practitioner
    end
    @content  = Letter::Renderer.new(@patient, @template).render(embed_variables).content

    recipient_email = @patient.email
    attachments["invoice_#{@invoice.invoice_number}.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "invoice_#{@invoice.invoice_number}",
          template: 'pdfs/invoice',
          locals: {
            invoice: @invoice
          }
        )
      )
    @template.attachments.each do |template_atm|
      attachments[template_atm.attachment_file_name] =
        Paperclip.io_adapters.for(template_atm.attachment).read
    end

    # Create communication
    com = @business.communications.create!(
      message_type: Communication::TYPE_EMAIL,
      category: 'invoice_send',
      linked_patient_id: @patient.id,
      recipient: @patient,
      message: @content,
      source: @invoice
    )

    com_delivery = CommunicationDelivery.create!(
      communication_id: com.id,
      recipient: @patient.email,
      tracking_id: SecureRandom.base58(32),
      last_tried_at: Time.current,
      status: CommunicationDelivery::STATUS_SCHEDULED,
      provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
    )

    add_sendgrid_delivery_tracking_header(com_delivery.tracking_id)

    subject = @template.email_subject.presence || "Invoice ##{@invoice.invoice_number} - #{@business.name}"

    mail(business_accounting_email_options(@business).merge(
      to: recipient_email,
      subject: subject
    ))
  end

  def outstanding_invoice_reminder(invoice, options = {})
    @invoice  = invoice
    @business = @invoice.business
    @patient  = invoice.patient
    @practitioner = @invoice.practitioner
    @template = @business.get_communication_template('outstanding_invoice_reminder')
    embed_variables = [
      @business, @invoice, @patient
    ]
    unless @practitioner.nil?
      embed_variables << @practitioner
    end
    @content = Letter::Renderer.new(@patient, @template).render(embed_variables).content

    recipient_email = @patient.email.presence

    attachments["invoice_#{@invoice.invoice_number}.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "invoice_#{@invoice.invoice_number}",
          template: 'pdfs/invoice',
          locals: {
            invoice: @invoice
          }
        )
      )

    @template.attachments.each do |template_atm|
      attachments[template_atm.attachment_file_name] =
        Paperclip.io_adapters.for(template_atm.attachment).read
    end

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    subject = @template.email_subject.presence || "Outstanding invoice reminder - #{@business.name}"

    mail(business_accounting_email_options(@business).merge(
      to: recipient_email,
      subject: subject
    ))
  end

  def send_to_contact(invoice, contact, message)
    @invoice = invoice
    @patient = invoice.patient
    @business = invoice.business
    @contact = contact
    @message = message

    attachments["Invoice_#{@invoice.invoice_number}.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "invoice_#{@invoice.invoice_number}",
          template: 'pdfs/invoice',
          locals: {
            invoice: @invoice
          }
        )
      )

    return false if contact&.email.blank?

    # Create communication
    com = @business.communications.create(
      message_type: Communication::TYPE_EMAIL,
      category: 'invoice_send',
      linked_patient_id: @patient.id,
      recipient: contact,
      message: message,
      source: invoice
    )

    com_delivery = CommunicationDelivery.create!(
      communication_id: com.id,
      recipient: contact.email,
      tracking_id: SecureRandom.base58(32),
      last_tried_at: Time.current,
      status: CommunicationDelivery::STATUS_SCHEDULED,
      provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
    )

    add_sendgrid_delivery_tracking_header(com_delivery.tracking_id)

    subject =
      if @invoice.paid?
        "Paid invoice ##{@invoice.invoice_number}"
      else
        "Invoice ##{@invoice.invoice_number}"
      end

    subject << " - #{@business.name}"

    mail(business_accounting_email_options(@business).merge(
      to: contact.email,
      subject: subject
    ))
  end

  def outstanding_invoice_reminder_to_contact(invoice, contact, options = {})
    @invoice = invoice
    @business = invoice.business
    @contact = contact

    attachments["invoice_#{@invoice.invoice_number}.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "invoice_#{@invoice.invoice_number}",
          template: 'pdfs/invoice',
          locals: {
            invoice: @invoice
          }
        )
      )

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_accounting_email_options(@business).merge(
      to: contact.email,
      subject: "Outstanding invoice reminder - #{@business.name}"
    ))
  end

  def send_to_email(invoice, email, message)
    @invoice = invoice
    @business = invoice.business
    @message = message

    attachments["Invoice_#{@invoice.invoice_number}.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "invoice_#{@invoice.invoice_number}",
          template: 'pdfs/invoice',
          locals: {
            invoice: @invoice
          }
        )
      )

    subject =
      if @invoice.paid?
        "Paid invoice ##{@invoice.invoice_number}"
      else
        "Invoice ##{@invoice.invoice_number}"
      end

    subject << " - #{@business.name}"

    mail(business_accounting_email_options(@business).merge(
      to: email,
      subject: subject
    ))
  end

  def payment_remittance(invoice, trigger_payment, options = {})
    @invoice  = invoice
    @business = @invoice.business
    @patient  = invoice.patient
    @practitioner = @invoice.practitioner

    @template = @business.get_communication_template(CommunicationTemplate::TEMPLATE_ID_INVOICE_PAYMENT_REMITTANCE)
    embed_variables = [
      @business, @invoice, @patient
    ]
    unless @practitioner.nil?
      embed_variables << @practitioner
    end
    @content = Letter::Renderer.new(@patient, @template).render(embed_variables).content

    attachments["invoice_#{@invoice.invoice_number}.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "invoice_#{@invoice.invoice_number}",
          template: 'pdfs/invoice',
          locals: {
            invoice: @invoice
          }
        )
      )

    @template.attachments.each do |template_atm|
      attachments[template_atm.attachment_file_name] =
        Paperclip.io_adapters.for(template_atm.attachment).read
    end

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    subject = @template.email_subject.presence || "Payment remittance - Invoice ##{@invoice.invoice_number} - #{@business.name}"

    mail(business_accounting_email_options(@business).merge(
      to: @patient.email,
      subject: subject
    ))
  end

  def payment_remittance_to_contact(invoice, trigger_payment, contact, options = {})
    @invoice  = invoice
    @business = @invoice.business
    @patient  = @invoice.patient
    @contact  = contact
    @practitioner = @invoice.practitioner

    @template = @business.get_communication_template(CommunicationTemplate::TEMPLATE_ID_INVOICE_PAYMENT_REMITTANCE)
    embed_variables = [
      @business, @invoice, @patient
    ]
    unless @practitioner.nil?
      embed_variables << @practitioner
    end
    @content = Letter::Renderer.new(@patient, @template).render(embed_variables).content

    attachments["invoice_#{@invoice.invoice_number}.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "invoice_#{@invoice.invoice_number}",
          template: 'pdfs/invoice',
          locals: {
            invoice: @invoice
          }
        )
      )

    @template.attachments.each do |template_atm|
      attachments[template_atm.attachment_file_name] =
        Paperclip.io_adapters.for(template_atm.attachment).read
    end

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    subject = @template.email_subject.presence || "Payment remittance - Invoice ##{@invoice.invoice_number} - #{@business.name}"

    mail(business_accounting_email_options(@business).merge(
      to: @contact.email,
      subject: subject
    ))
  end
end
