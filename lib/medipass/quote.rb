module Medipass
  class Quote
    # @see https://developers.medipass.io/docs?role=pms&v=2#create-a-quote-api-def
    def self.create(account_secret, claim_body)
      Medipass.api_call(
        :post,
        '/quotes',
        claim_body,
        {
          'Authorization' => "Bearer #{account_secret}"
        }
      )
    end
  end
end
