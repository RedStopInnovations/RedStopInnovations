if ENV['SENTRY_DSN'].present?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    config.excluded_exceptions = [
      'ActionController::RoutingError',
      'ActiveRecord::RecordNotFound',
      'ActionController::ParameterMissing',
      'ActionController::UnknownFormat',
      'AbstractController::ActionNotFound',
      'ActionDispatch::Http::Parameters::ParseError',
      'Rack::QueryParser::InvalidParameterError',
      'Addressable::URI::InvalidURIError',
      'ActionDispatch::RemoteIp::IpSpoofAttackError',
      'ActionDispatch::Http::MimeNegotiation::InvalidType',
      'ActionController::Redirecting::UnsafeRedirectError',
      'Net::SMTPSyntaxError',
      'SignalException',
      'ActionController::RespondToMismatchError',
      'ActionController::InvalidAuthenticity',
      'Puma::HttpParserError'
    ]

    # Set tracesSampleRate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production
    config.traces_sample_rate = 0.5
  end
end
