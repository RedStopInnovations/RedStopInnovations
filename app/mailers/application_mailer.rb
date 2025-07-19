class ApplicationMailer < ActionMailer::Base
  DEFAULT_SENDER = ENV.fetch('DEFAULT_SENDER_EMAIL', 'info@example.com')

  default from: DEFAULT_SENDER,
          sender: DEFAULT_SENDER

  layout 'mailer'
  append_view_path Rails.root.join('app', 'views', 'mailers')

  protected

  def business_email_options(business)
    options = {
      from: "#{business.name} <#{DEFAULT_SENDER}>"
    }

    if business.email?
      options[:reply_to] = business.email
    end

    options
  end

  def business_accounting_email_options(business)
    options = {
      from: "#{business.name} <#{DEFAULT_SENDER}>"
    }

    if business.accounting_email?
      options[:reply_to] = business.accounting_email
    elsif business.email?
      options[:reply_to] = business.email
    end

    options
  end

  # @see: https://docs.sendgrid.com/for-developers/sending-email/building-an-x-smtpapi-header
  # @see: https://docs.sendgrid.com/for-developers/sending-email/unique-arguments
  def add_sendgrid_delivery_tracking_header(delivery_tracking_id)
    headers['X-SMTPAPI'] = {
      unique_args: {App::EMAIL_DELIVERY_TRACKING_FIELD_NAME => "#{delivery_tracking_id}"}
    }.to_json
  end
end
