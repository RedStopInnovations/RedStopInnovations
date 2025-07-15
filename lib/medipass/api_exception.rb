module Medipass
  class ApiException < Exception
    def initialize(httparty_response)
      @httparty_response = httparty_response

      super error_message
    end

    def status_code
      parsed_response_body['statusCode']
    end

    def error_code
      parsed_response_body['errorCode']
    end

    def error_message
      parsed_response_body['message'] ||
        "Error: #{parsed_response_body['error']}. Status code: #{status_code}"
    end

    private

    def response
      @httparty_response
    end

    def parsed_response_body
      response.parsed_response rescue {}
    end
  end
end
