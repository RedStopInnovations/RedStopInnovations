module RansackAuthorization
  module Appointment
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        _ransackers.keys + [
          'id',
          'patient_id',
          'appointment_type_id',
          'start_time'
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        []
      end

      def self.ransortable_attributes(auth_object = nil)
        [
          'start_time',
          'created_at'
        ]
      end
    end
  end
end
