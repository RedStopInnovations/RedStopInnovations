module ClaimingApi
  DEVELOPMENT_BASE_URL = 'https://api.claiming.com.au/dev'
  PRODUCTION_BASE_URL  = 'https://api.claiming.com.au/v1'

  class Client
    include HTTParty
    include Apis::Verification
    include Apis::Claim
    include Apis::AuthGroup
    include Apis::Provider

    # TODO: use explicitly internal config rather than Rails
    if Rails.env.production? || true
      base_uri PRODUCTION_BASE_URL
      pem File.read(Rails.root.join('config/certs/claiming_prod.pem'))
    else
      base_uri DEVELOPMENT_BASE_URL
      pem File.read(Rails.root.join('config/certs/claiming_dev.pem'))
    end

    headers 'Content-Type' => 'application/json'

    debug_output

    delegate :get, :post, :put, to: :class

    def whoami
      get('/whoami')
    end
  end
end
