class BusinessInvoiceMailer < ApplicationMailer
  helper :application

  def business_invoice_mail(business_invoice, subscription)
    @business_invoice = business_invoice
    @business = @business_invoice.business

    recipient =
      if subscription.email?
        subscription.email
      else
        @business.email.presence || @business.users.role_administrator.order(id: :asc).first.try(:email)
      end

    attachments["subscription-invoice-#{@business_invoice.invoice_number}.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "Invoice ##{@business_invoice.invoice_number}",
          template: 'pdfs/business_invoice',
          locals: {
            business_invoice: @business_invoice
          }
        )
      )
    mail(
      to: recipient,
      subject: "Subscription invoice ##{@business_invoice.invoice_number}"
    )
  end
end
