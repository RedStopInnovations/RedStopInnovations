class ValidateRequestParams
  INVALID_CHARACTERS = [
    "\u0000" # null bytes
  ].freeze

  UTF8_SANITIZE_ENV_KEYS = %w(
    HTTP_REFERER
    PATH_INFO
    REQUEST_URI
    REQUEST_PATH
    QUERY_STRING
  )

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    UTF8_SANITIZE_ENV_KEYS.each do |key|
      string = env[key].to_s
      valid = Addressable::URI.escape(string).force_encoding('UTF-8').valid_encoding?
      return [ 400, { }, [ 'Bad request' ] ] unless valid
    end

    invalid_characters_regex = Regexp.union(INVALID_CHARACTERS)

    has_invalid_character = request.params.values.any? do |value|
      value.match?(invalid_characters_regex) if value.respond_to?(:match)
    end

    if has_invalid_character
      return [400, {}, ["Bad Request"]]
    end

    @app.call(env)
  end
end