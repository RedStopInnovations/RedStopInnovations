module Request
  module ApiHelper
    def json_response
      @json_response ||= JSON.parse(response.body, symbolize_names: true)
    end

    def generate_api_key(user)
      token = ApiKey.generate_token
      ApiKey.create!(token: token, user_id: user.id, active: true)
    end

    def auth_headers(key)
      {
        'X-API-KEY' => key
      }
    end
  end
end
