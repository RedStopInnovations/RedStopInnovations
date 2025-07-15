class SendInvoiceToOthersService
  class Exception < StandardError; end

  # @param invoice Invoice
  # @param sender User
  # @param form SendOthersForm
  def call(invoice, sender, form)
    business = sender.business
    contacts = business.contacts.where("email <> ''").where(id: form.contact_ids)

    send_at = Time.current

    contacts.each do |contact|
      InvoiceMailer.send_to_contact(invoice, contact, form.message).deliver_later

      if contact.id == invoice.invoice_to_contact_id
        invoice.update_column :last_send_contact_at, send_at
      end
    end

    form.emails.each do |email|
      InvoiceMailer.send_to_email(invoice, email, form.message).deliver_later
    end

    invoice.update_columns(
      last_send_at: send_at
    )
  end
end
