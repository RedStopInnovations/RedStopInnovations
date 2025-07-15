module Webhook
  module Appointment
    class Serializer
      attr_reader :appointment

      def initialize(appointment)
        @appointment = appointment
      end

      def as_json(options = {relations: true})
        attrs = appointment.attributes.symbolize_keys.slice(
          :id,
          :start_time,
          :end_time,
          :booked_online,
          :is_completed,
          :notes,
          :updated_at,
          :created_at
        )

        if options[:relations]
          attrs[:availability] =
            Webhook::Availability::Serializer.new(appointment.availability).as_json({relations: false})
          attrs[:patient] =
            Webhook::Patient::Serializer.new(appointment.patient).as_json
          attrs[:practitioner] =
            Webhook::Practitioner::Serializer.new(appointment.practitioner).as_json
          attrs[:appointment_type] =
            Webhook::AppointmentType::Serializer.new(appointment.appointment_type).as_json
        end
        attrs
      end
    end
  end
end
