module RansackAuthorization
  module Task
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        ["id", "name", "description", "due_on", "owner_id", "patient_id", "priority", "created_at", "updated_at"]
      end

      def self.ransackable_associations(auth_object = nil)
        ['patient', 'owner', 'task_users']
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
