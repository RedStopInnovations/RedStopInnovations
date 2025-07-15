module ClaimingApi
  class Configuration
    AVAILABLE_ENVIRONMENTS = %w(development production)
    AVAILABLE_CONFIGS = %i(ssl_cert environment)

    attr_accessor *AVAILABLE_CONFIGS

    def initialize(attrs = {})
      attrs.slice(*AVAILABLE_CONFIGS).each do |attr, val|
        instance_variable_set "@#{attr}", val
      end
    end

    def production?
      environment.to_s == 'production'
    end

    def development?
      environment.to_s == 'development'
    end
  end
end
