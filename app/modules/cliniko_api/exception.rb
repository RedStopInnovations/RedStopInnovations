module ClinikoApi
  class Exception < StandardError
    attr_reader :api_response, :status_code, :response_text

    def initialize(response)
      @api_response = response
      @status_code  = response.code
      @response_text  = response.parsed_response
      super "Status: #{@status_code}. Response: #{@response_text}"
    end
  end
end
