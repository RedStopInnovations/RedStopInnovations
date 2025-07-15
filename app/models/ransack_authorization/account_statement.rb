module RansackAuthorization
  module AccountStatement
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        [
          'number',
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        []
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
