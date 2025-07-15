module ClinikoApi
  class Client
    extend ApiHelper

    USER_AGENT   = 'curl' # Dont tell them who they are :)

    attr_reader :api_key
    attr_reader :shard

    resource :Patient
    resource :TreatmentNote
    resource :Contact

    def initialize(api_key, shard = 'au1')
      @api_key = api_key
      @shard = shard
    end

    # Call api and return parsed JSON response in hash
    #
    # @param method          Symbol The HTTP verb
    # @param url             String The url of request
    # @param payload         Hash   The body or query parameters
    def call(method, url, payload = {}, headers = {})
      default_headers = {
        'User-Agent'   => USER_AGENT,
        'Accept'       => 'application/json',
        'Content-Type' => 'application/json'
      }
      request_headers = default_headers.merge(headers)

      request_url =
        if url.start_with?('http') || url.start_with?('https')
          url
        else
          build_endpoint_url_for(url)
        end

      # Call and handle response
      response = HTTParty.send(
        method,
        request_url,
        query: payload,
        headers: request_headers,
        basic_auth: { username: api_key }
      )

      if response.success?
        response.parsed_response
      else
        raise ClinikoApi::Exception.new(response)
      end
    end

    protected

    def build_endpoint_url_for(path)
      "https://api.#{shard}.cliniko.com/v1/#{path}"
    end
  end
end
