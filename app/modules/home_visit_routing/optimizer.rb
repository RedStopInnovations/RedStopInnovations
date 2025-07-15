module HomeVisitRouting
  class Optimizer
    def call(availability_id)
      availability = Availability.find availability_id

      return if availability.appointments.count.zero?

      appointments = availability.
                     appointments.
                     includes(:patient, :arrival).
                     to_a

      first_appt = appointments[0]

      if appointments.count == 1
        first_appt_arrival = first_appt.arrival || first_appt.build_arrival
        if first_appt_arrival.persisted? && first_appt_arrival.arrival_at != availability.start_time
          first_appt_arrival.sent_at = nil
        end

        first_appt_arrival.arrival_at = availability.start_time
        first_appt_arrival.travel_distance = 0
        first_appt_arrival.travel_duration = 0
        first_appt_arrival.travel_start_address = first_appt.patient.full_address
        first_appt_arrival.travel_dest_address = first_appt.patient.full_address
        first_appt_arrival.save!
        availability.update(
          driving_distance: 0,
          routing_status: Availability::ROUTING_STATUS_OK
        )
      else
        # start = availability.full_address_for_geocoding
        # desc = availability.full_address_for_geocoding
        start = availability.to_coordinates.join(',')
        desc = start

        waypoints = appointments.map do |appt|
          # appt.patient.full_address_for_geocoding
          appt.patient.to_coordinates.join(',')
        end

        direction_query_url = GoogleApiHelper::build_direction_query_url(
          start,
          desc,
          waypoints,
          optimize: true
        )
        req = HTTParty.get(direction_query_url)

        result = req.parsed_response
        if result['status'] == 'OK'
          optimized_route = result['routes'][0]
          waypoint_order = optimized_route['waypoint_order']
          ordered_appts = []

          # Build the appointments list in the optimized order
          waypoint_order.each_with_index do |waypoint_index, index|
            ordered_appts[index] = appointments[waypoint_index]
          end

          total_travel_distance = 0
          start_travel_at = availability.start_time

          ActiveRecord::Base.transaction do
            ordered_appts.each_with_index do |appt, index|
              route_leg = optimized_route['legs'][index]
              appt_arrival = appt.arrival || appt.build_arrival

              if index === 0
                appt_arrival.arrival_at = start_travel_at
                appt_arrival.travel_distance = 0
                appt_arrival.travel_duration = 0
                appt_arrival.travel_start_address = appt.patient.full_address
                appt_arrival.travel_dest_address = appt.patient.full_address
              else
                prev_appt = ordered_appts[index - 1]
                travel_duration = route_leg['duration']['value']
                travel_distance = route_leg['distance']['value']

                appt_arrival.arrival_at = start_travel_at + travel_duration.seconds
                appt_arrival.travel_distance = travel_distance
                appt_arrival.travel_duration = travel_duration
                appt_arrival.travel_start_address = prev_appt.patient.full_address
                appt_arrival.travel_dest_address = appt.patient.full_address
                total_travel_distance += travel_distance
              end

              if appt_arrival.persisted? && appt_arrival.arrival_at_changed?
                appt_arrival.sent_at = nil
              end

              appt_arrival.save!
              appt.update_attribute :order, index

              start_travel_at = appt_arrival.arrival_at + appt.appointment_type.duration.minutes + appt.break_times.to_i.minutes
            end

            availability.update(
              driving_distance: total_travel_distance,
              routing_status: Availability::ROUTING_STATUS_OK
            )
          end

        elsif ['NOT_FOUND', 'ZERO_RESULTS'].include?(result['status'])
          availability.update(
            routing_status: Availability::ROUTING_STATUS_NOT_FOUND
          )
        else
          availability.update(
            routing_status: Availability::ROUTING_STATUS_ERROR
          )
          Sentry.capture_exception(
            StandardError.new("Google Map direction API error. Status: #{result['status']}")
          )
        end
      end
    end
  end
end
