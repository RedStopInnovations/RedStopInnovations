module RansackAuthorization
  module PatientCase
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        [
          'status',
          'created_at',
          'updated_at'
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        ['case_type', 'practitioner', 'patient']
      end

      def self.ransortable_attributes(auth_object = nil)
        [
          'created_at',
          'updated_at'
        ]
      end
    end
  end
end
