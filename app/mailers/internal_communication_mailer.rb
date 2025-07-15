class InternalCommunicationMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper

  def send_email(sender:, recipient:, subject:, body:)
    @body = body
    mail(
      from: "#{sender.full_name}<#{sender.email}>",
      to: recipient.email,
      subject: subject,
      content_type: "text/html",
      body: simple_format(body),
    )
  end
end
