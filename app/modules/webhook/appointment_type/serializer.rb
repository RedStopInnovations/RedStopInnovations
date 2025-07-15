module Webhook
  module AppointmentType
    class Serializer
      attr_reader :appointment_type

      def initialize(appointment_type)
        @appointment_type = appointment_type
      end

      def as_json(options = {})
        attrs = appointment_type.attributes.symbolize_keys.slice(
          :id,
          :name,
          :description,
          :duration,
          :reminder_enable
        )
        attrs
      end
    end
  end
end
