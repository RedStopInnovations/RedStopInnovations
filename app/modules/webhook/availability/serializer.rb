module Webhook
  module Availability
    class Serializer

      attr_reader :availability

      def initialize(availability)
        @availability = availability
      end

      def as_json(options = {relations: true})
        attrs = availability.attributes.symbolize_keys.slice(
          :id,
          :start_time,
          :end_time,
          :address1,
          :address2,
          :city,
          :state,
          :postcode,
          :country,
          :max_appointment,
          :service_radius,
          :latitude,
          :longitude,
          :allow_online_bookings,
          :updated_at,
          :created_at
        )

        attrs[:availability_type] = {
          1 => 'HOME_VISIT',
          4 => 'FACILITY'
        }[availability.availability_type_id]

        if options[:relations]
          attrs[:practitioner] = Webhook::Practitioner::Serializer.new(availability.practitioner).as_json

          attrs[:appointments] = []

          availability.appointments.each do |appt|
            attrs[:appointments] << Webhook::Appointment::Serializer.new(appt).as_json({relations: false})
          end
        end

        attrs
      end
    end
  end
end
