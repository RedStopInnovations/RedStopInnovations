module Medipass
  class ApiClient
    LIVE_BASE_API_URL        = 'https://api-au.medipass.io/v2'
    DEVELOPMENT_API_BASE_URL = 'https://dev-api-au.medipass.io/v2'

    attr_reader :config

    # @param config Medipass::Configuration
    def initialize(config)
      @config = config
    end

    # Call api and return parsed JSON response in hash
    #
    # @param method          Symbol The HTTP verb
    # @param path            String The full path of request
    # @param payload         Hash   The body or query parameters
    # @return Hash
    def call(method, path, payload = {}, headers = {})
      default_headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'Authorization' => authorization_header
      }
      request_headers = default_headers.merge(headers)

      # Call and handle response
      case method
      when :get
        response = HTTParty.send(
          method,
          api_url_for(path),
          query: payload,
          headers: request_headers
        )
      when :post, :put, :delete
        response = HTTParty.send(
          method,
          api_url_for(path),
          {
            body: payload.to_json,
            headers: request_headers
          }
        )
      end

      if response.success?
        response.parsed_response
      else
        raise Medipass::ApiException.new(response)
      end
    end

    protected

    def api_url_for(path)
      base =
        if config.development?
          DEVELOPMENT_API_BASE_URL
        else
          LIVE_BASE_API_URL
        end
      "#{base}#{path}"
    end

    def authorization_header
      "Bearer #{config.api_key}"
    end
  end
end
