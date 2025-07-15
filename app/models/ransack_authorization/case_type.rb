module RansackAuthorization
  module CaseType
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        [
          'title',
          'created_at',
          'updated_at'
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        []
      end
    end
  end
end
