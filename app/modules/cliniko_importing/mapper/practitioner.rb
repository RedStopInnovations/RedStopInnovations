module ClinikoImporting
  module Mapper
    module Practitioner
      # @param cliniko_practitioner ClinikoApi::Resource::Practitioner
      def self.build(cliniko_practitioner)
        local_practitioner_attrs = {
          first_name: cliniko_practitioner.first_name,
          last_name: cliniko_practitioner.last_name
        }
      end
    end
  end
end
