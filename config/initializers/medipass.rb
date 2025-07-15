require 'medipass'

Medipass.configure do |config|
  config.api_key = ENV['MEDIPASS_API_KEY']
  config.master_api_key = ENV['MEDIPASS_MASTER_API_KEY']
  config.environment = ENV.fetch('MEDIPASS_ENVIRONMENT', 'development')
end
