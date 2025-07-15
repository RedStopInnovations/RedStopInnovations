class ContactAccountStatementMailer < ApplicationMailer
  def send_to_contact(account_statement, options = {})
    @account_statement = account_statement
    @contact = @account_statement.source
    @business = @account_statement.business

    attachments['account_statement.pdf'] = account_statement.pdf.read

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_accounting_email_options(@business).merge(
      to: @contact.email,
      subject: 'Account Statement'
    ))
  end
end
