module InvoicesHelper
  def patient_case_options_for_invoice(invoice)
    options = []
    options << ['-- Select one --', nil]
    if invoice.patient.present?
      invoice.patient.patient_cases.includes(:case_type).each do |patient_case|
        options << [
          "#{patient_case.case_type.try(:title)} - #{patient_case.status}",
          patient_case.id
        ]
      end
    end
    options
  end

  def invoice_to_contacts_options_for_invoice(invoice)
    options = []
    options << ['-- Select one --', nil]
    if invoice.patient.present?
      invoice.patient.invoice_to_contacts.each do |contact|
        options << [ contact.business_name, contact.id ]
      end
    end
    options
  end

  def default_invoice_email_message_to_contacts(business, sender, invoice)
    msg = "To whom it may concern,\n\n"\
    "Please find attached the invoice. We appreciated your support of #{business.name}. If you have any questions don't hesitate to contact me by email or phone.\n\n"\

    if business.stripe_payment_available?
      invoice_payment_url = public_invoice_payment_url(
        token: invoice.public_token
      )
      msg << "To pay the invoice, please visit this page: #{invoice_payment_url}\n\n"
    end

    msg << "#{sender.full_name},\n"\
      "#{business.phone}\n"

    msg
  end
end
