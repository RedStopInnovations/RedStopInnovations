module HomeVisitRouting
  class GroupAppointmentArrivalCalculate
    def call(availability_id)
      availability = Availability.find availability_id

      return if availability.appointments.count.zero?

      appointments = availability.
                     appointments.
                     includes(:patient, :arrival).
                     order(order: :ASC).
                     to_a

      appointments.each do |appt|
        arrival = appt.arrival || appt.build_arrival

        if arrival.persisted? && arrival.arrival_at != availability.start_time
          arrival.sent_at = nil
        end

        arrival.arrival_at = availability.start_time
        arrival.travel_distance = 0
        arrival.travel_duration = 0
        arrival.save!
      end

    end
  end
end
