class PatientAccountStatementMailer < ApplicationMailer
  def send_to_patient(account_statement, options = {})
    @account_statement = account_statement
    @patient = @account_statement.source
    @business = @account_statement.business

    attachments['account_statement.pdf'] = account_statement.pdf.read

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_accounting_email_options(@business).merge(
      to: @patient.email,
      subject: 'Account Statement'
    ))
  end

  def send_to_contact(account_statement, contact, message, options = {})
    @account_statement = account_statement
    @contact = contact
    @message = message
    @business = @account_statement.business

    attachments['account_statement.pdf'] = account_statement.pdf.read

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_accounting_email_options(@business).merge(
      to: contact.email,
      subject: "Account Statement"
    ))
  end

  def send_to_email(account_statement, email, message = nil)
    @account_statement = account_statement
    @message = message
    @business = @account_statement.business

    attachments['account_statement.pdf'] = account_statement.pdf.read

    mail(business_accounting_email_options(@business).merge(
      to: email,
      subject: "Account Statement"
    ))
  end
end
