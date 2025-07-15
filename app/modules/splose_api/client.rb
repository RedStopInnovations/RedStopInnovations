module SploseApi
  class Client
    USER_AGENT   = 'curl'

    def initialize(api_key)
      @api_key = api_key
    end

    # Call api and return parsed JSON response in hash
    #
    # @param method          Symbol The HTTP verb
    # @param url             String The url of request
    # @param payload         Hash   The body or query parameters
    def call(method, url, payload = {}, headers = {})
      default_headers = {
          "User-Agent" => "curl",
          "Accept" => "application/json",
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{@api_key}",
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
      )

      if response.success?
        response.parsed_response
      else
        raise SploseApi::Exception.new(response)
      end
    end

    protected

    def build_endpoint_url_for(path)
      "https://api.splose.com#{path}"
    end
  end
end
