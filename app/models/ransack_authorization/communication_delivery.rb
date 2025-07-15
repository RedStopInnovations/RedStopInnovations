module RansackAuthorization
  module CommunicationDelivery
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        [
          'status',
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
