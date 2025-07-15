module ClinikoApi
  module ApiHelper
    def resource(resource_name)
      define_method resource_name do
        var_name = "@#{resource_name}".to_sym
        unless instance_variable_defined?(var_name)
          instance_variable_set(var_name, ClinikoApi::Resource.const_get(resource_name).new(self))
        end
        instance_variable_get(var_name)
      end
    end
  end
end
