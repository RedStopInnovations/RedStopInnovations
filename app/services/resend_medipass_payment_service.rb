class ResendMedipassPaymentService
  class Exception < StandardError; end

  attr_reader :invoice, :business, :medipass_transaction

  def call(invoice)
    @invoice = invoice
    @business = invoice.business
    @medipass_transaction = invoice.pending_medipass_transaction

    if medipass_transaction.nil?
      raise Exception, "No pending Medipass payment request to send."
    end

    resend_payment_request
  end

  private

  def resend_payment_request
    begin
      Medipass::Transaction.payment_request(
        @business.medipass_account.api_key,
        @medipass_transaction.transaction_id
      )

      @medipass_transaction.update_columns(
        requested_at: Time.current
      )
    rescue Medipass::ApiException => e
      raise Exception, e.message
    end
  end
end
