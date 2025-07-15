require 'claiming_api'

ClaimingApi.configure do |config|
  env = ENV.fetch('CLAIMING_ENVIRONMENT', 'development')
  config.environment = env
end
