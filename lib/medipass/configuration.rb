module Medipass
  class Configuration
    AVAILABLE_ENVIRONMENTS = %w(development live)
    AVAILABLE_CONFIGS = %i(api_key master_api_key environment)

    attr_accessor *AVAILABLE_CONFIGS

    def initialize(attrs = {})
      attrs.slice(*AVAILABLE_CONFIGS).each do |attr, val|
        instance_variable_set "@#{attr}", val
      end
    end

    def development?
      environment.to_s == 'development'
    end

    def live?
      environment.to_s == 'live'
    end
  end
end

