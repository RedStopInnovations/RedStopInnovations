module RansackAuthorization
  module WaitList
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        [
          'profession',
          'appointment_type_id',
          'practitioner_id',
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        ['patient']
      end

      def self.ransortable_attributes(auth_object = nil)
        [
          'created_at',
          'updated_at',
        ]
      end
    end
  end
end
