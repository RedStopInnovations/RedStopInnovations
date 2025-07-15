module Medipass
  class Transaction

    def self.payment_request(account_secret, transaction_id)
      Medipass.api_call(
        :post,
        "/transactions/#{transaction_id}/paymentrequests",
        { transactionId: transaction_id },
        {
          'Authorization' => "Bearer #{account_secret}"
        }
      )
    end

    # @see https://developers.medipass.io/docs?role=pms&v=2#create-an-invoice-api-def
    def self.create(account_secret, claim_body)
      Medipass.api_call(
        :post,
        '/invoices',
        claim_body,
        {
          'Authorization' => "Bearer #{account_secret}"
        }
      )
    end

    # @see https://developers.medipass.io/docs?role=pms&v=2#cancel-a-transaction-api-def
    def self.cancel(account_secret, transaction_id, params = {})
      Medipass.api_call(
        :post,
        "/transactions/#{transaction_id}/cancellations",
        params,
        {
          'Authorization' => "Bearer #{account_secret}"
        }
      )
    end

    # @see https://developers.medipass.io/docs?role=pms&v=2#get-a-transaction-api-def
    def self.find(account_secret, transaction_id)
      Medipass.api_call(
        :get,
        "/transactions/#{transaction_id}",
        {},
        {
          'Authorization' => "Bearer #{account_secret}"
        }
      )
    end
  end
end
