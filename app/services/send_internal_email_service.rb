class SendInternalEmailService
  attr_reader :sender, :recipient, :form_request

  def call(sender:, form_request:)
    @sender = sender
    @form_request = form_request
    @recipient = User.find(form_request.user_id)

    InternalCommunicationMailer.send_email(
      sender: sender,
      recipient: recipient,
      subject: form_request.subject,
      body: form_request.body
    ).deliver_later
  end
end
