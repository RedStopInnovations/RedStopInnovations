require 'claiming_api/configuration'
module ClaimingApi
  class << self
    def config=(attrs)
      @config = ClaimingApi::Configuration.new(attrs)
    end

    def config
      @config ||= ClaimingApi::Configuration.new
    end

    def configure
      yield(config)
    end
  end
end
require 'claiming_api/apis/verification'
require 'claiming_api/apis/claim'
require 'claiming_api/apis/auth_group'
require 'claiming_api/apis/provider'
require 'claiming_api/client'
