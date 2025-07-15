require 'medipass/configuration'
require 'medipass/api_client'
require 'medipass/exception'
require 'medipass/api_exception'

require 'medipass/member'
require 'medipass/quote'
require 'medipass/transaction'

module Medipass
  class << self
    def config=(attrs)
      @config = Medipass::Configuration.new(attrs)
    end

    def config
      @config ||= Medipass::Configuration.new
    end

    def configure
      yield(config)
    end

    def http_client
      @http_client ||= Medipass::ApiClient.new(config)
    end

    def api_call(*args)
      http_client.call(*args)
    end
  end
end
