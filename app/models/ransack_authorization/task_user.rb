module RansackAuthorization
  module TaskUser
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        ["status", "completion_duration", "task_id", "updated_at", "user_id"]
      end

      def self.ransackable_associations(auth_object = nil)
        ['user']
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
