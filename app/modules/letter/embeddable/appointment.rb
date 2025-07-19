module Letter
  module Embeddable
    class Appointment < Base
      VARIABLES = [
        'Appointment.StartTime',
        'Appointment.EndTime',
        'Appointment.Date',
        'Appointment.ArrivalTime',
        'Appointment.CancelLink',
        'Appointment.TravelStartAddress',
        'Appointment.TravelDestinationAddress',
        'Appointment.SatisfactionReviewURL',
      ]

      # @param appointment ::Appointment
      def initialize(appointment)
        @appointment = appointment
        super map_attributes
      end

      private

      def map_attributes
        pract_tz = @appointment.practitioner.user_timezone
        appt_start_time = @appointment.start_time_in_practitioner_timezone
        appt_end_time = @appointment.end_time_in_practitioner_timezone
        arrival_time_formated = ''
        travel_start_address = ''
        travel_dest_address = ''
        public_travel_start_address = ''

        if @appointment.arrival
          arrival_at = @appointment.arrival.arrival_at.in_time_zone(pract_tz)
          arrival_time_formated = arrival_at.strftime("%l:%M%P") + " on " + arrival_at.strftime("%a, %d %b")
          travel_start_address = @appointment.arrival.travel_start_address
          travel_dest_address = @appointment.patient.short_address
          if travel_start_address
            public_travel_start_address = mask_travel_start_address(travel_start_address)
          end
        end

        # Use availability start address
        if public_travel_start_address.empty?
          public_travel_start_address = @appointment.availability.short_address
        end

        # cancel_url = Rails.application.routes.url_helpers.frontend_appointments_cancel_show_url(
        #   token: @appointment.public_token
        # )
        cancel_url = '#' # Temporarily disable cancel link

        cancel_link_tag = "<a href=\"#{cancel_url}\">Cancel appointment</a>"

        review_url = Rails.application.routes.url_helpers.add_review_url(
          appointment_token: @appointment.public_token
        )

        {
          'Appointment.StartTime' => appt_start_time.strftime("%l:%M%P"),
          'Appointment.EndTime' => appt_end_time.strftime("%l:%M%P (%Z)"),
          'Appointment.Date' => appt_start_time.strftime("%a, %d %b %Y"),
          'Appointment.ArrivalTime' => arrival_time_formated,
          'Appointment.CancelLink' => cancel_link_tag,
          'Appointment.TravelStartAddress' => public_travel_start_address,
          'Appointment.TravelDestinationAddress' => travel_dest_address,
          'Appointment.SatisfactionReviewURL' => review_url
        }
      end

      # Mask the start address for the privacy of other clients
      # travel_start_address is the full address
      def mask_travel_start_address(address)
        address_parts = address.split(', ')

        # Remove address1 and address2
        if address_parts.count == 6
          address_parts[0] = nil
          address_parts[1] = nil
        else
          address_parts[0] = nil
        end

        # Remove country
        address_parts[-1] = nil

        address_parts.compact!

        address_parts = address_parts.map do |part|
          part.to_s.strip
        end

        address_parts.join(' ')
      end
    end
  end
end
