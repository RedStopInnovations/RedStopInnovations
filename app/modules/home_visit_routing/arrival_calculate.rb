module HomeVisitRouting
  class ArrivalCalculate
    def call(availability_id)
      availability = Availability.find availability_id

      return if availability.appointments.count.zero?

      appointments = availability.
                     appointments.
                     includes(:patient, :arrival).
                     order(order: :ASC).
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
        first_appt_arrival.save!
        first_appt_arrival.travel_start_address = first_appt.patient.full_address
        first_appt_arrival.travel_dest_address = first_appt.patient.full_address
        availability.update(
          driving_distance: 0,
          routing_status: Availability::ROUTING_STATUS_OK
        )
      else

        # start = first_appt.patient.full_address_for_geocoding
        # desc = appointments[-1].patient.full_address_for_geocoding
        start = first_appt.patient.to_coordinates.join(',')
        desc = appointments[-1].patient.to_coordinates.join(',')
        waypoints = []

        appointments.each_with_index do |appt, idx|
          if idx != 0 && idx != appointments.count - 1
            # waypoints << appt.patient.full_address_for_geocoding
            waypoints << appt.patient.to_coordinates.join(',')
          end
        end

        direction_query_url = GoogleApiHelper::build_direction_query_url(
          start,
          desc,
          waypoints
        )
        req = HTTParty.get(direction_query_url)

        result = req.parsed_response
        if result['status'] == 'OK'
          total_travel_distance = 0

          first_appt = appointments[0]
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

          start_time = availability.start_time + first_appt.appointment_type.duration.minutes + first_appt.break_times.to_i.minutes

          result['routes'][0]['legs'].each_with_index do |leg, index|
            appointment = appointments[index + 1]
            prev_appt = appointments[index]
            start_time = start_time + leg['duration']['value'].seconds
            travel_distance = leg['distance']['value']
            total_travel_distance += travel_distance

            arrival = appointment.arrival || appointment.build_arrival
            if arrival.persisted? && arrival.arrival_at != start_time
              arrival.sent_at = nil
            end
            arrival.arrival_at = start_time
            arrival.travel_distance = travel_distance # Meters
            arrival.travel_duration = leg['duration']['value'] # Seconds
            arrival.travel_start_address = prev_appt.patient.full_address
            arrival.travel_dest_address = appointment.patient.full_address
            arrival.save!

            start_time = start_time + appointment.appointment_type.duration.minutes + appointment.break_times.to_i.minutes
          end

          availability.update(
            driving_distance: total_travel_distance,
            routing_status: Availability::ROUTING_STATUS_OK
          )

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
