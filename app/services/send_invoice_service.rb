class SendInvoiceService
  def call(invoice, sender)
    business = invoice.business

    if invoice.invoice_to_contact
      contact = invoice.invoice_to_contact

      if contact.email?
        message = build_default_invoice_email_message_to_contact(business, invoice, sender)
        InvoiceMailer.send_to_contact(invoice, contact, message).deliver_later
        invoice.update_column :last_send_contact_at, Time.current
      end
    else
      patient = invoice.patient

      if patient.email?
        InvoiceMailer.invoice_mail(invoice).deliver_later
        send_ts = Time.current
        invoice.update_columns(
          last_send_patient_at: send_ts,
          last_send_at: send_ts
        )
      end
    end
  end

  private

  def build_default_invoice_email_message_to_contact(business, invoice, sender)
    msg = "To whom it may concern,\n\n"\
      "Please find attached the invoice. We appreciated your support of #{business.name}. If you have any questions don't hesitate to contact me by email or phone.\n\n"

    if business.stripe_payment_available?
      invoice_payment_url = Rails.application.routes.url_helpers.public_invoice_payment_url(
        token: invoice.public_token
      )
      msg << "To pay the invoice - <a href=\"#{invoice_payment_url}\">Click Here</a>\n\n"
    end

    msg << "#{sender.full_name},\n"\
      "#{business.phone}"

    msg
  end
end