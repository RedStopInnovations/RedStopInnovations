class AvailabilityCachedStats
  def calculate(availability)
    stats = {}

    appointments = Appointment.
      where(availability_id: availability.id).
      where(cancelled_at: nil, deleted_at: nil).
      includes(:appointment_type, :arrival).
      to_a

    stats[:availability_duration] = (availability.end_time - availability.start_time).to_i

    if availability.home_visit? || availability.facility?
      stats[:remaining_availability_duration] = stats[:availability_duration]

      appointments_count = appointments.size
      stats[:appointments_count] = appointments_count

      if appointments_count > 0
        stats[:appointments_duration] = 0
        stats[:breaks_duration] = 0

        appointments.each do |appt|
          stats[:appointments_duration] += appt.appointment_type.duration.to_i * 60

          if appt.break_times.present?
            stats[:breaks_duration] += appt.break_times * 60
          end
        end

        stats[:remaining_availability_duration] -= (stats[:appointments_duration] + stats[:breaks_duration])
      else
        stats[:appointments_duration] = 0
      end
    end

    if availability.group_appointment?
      stats[:appointments_duration] = availability.group_appointment_type.duration * 60
      stats[:appointments_count] = 1
      stats[:remaining_availability_duration] = 0
    end

    if availability.home_visit?
      stats[:travel_duration] = 0
      stats[:travel_distance] = 0

      appointments.each do |appt|
        if appt.arrival
          if appt.arrival.travel_duration.present?
            stats[:travel_duration] += appt.arrival.travel_duration.to_i
          end

          if appt.arrival.travel_distance.present?
            stats[:travel_distance] += appt.arrival.travel_distance.to_i
          end
        end
      end

      stats[:remaining_availability_duration] -= stats[:travel_duration]
    end

    if stats.key?(:remaining_availability_duration)
      stats[:remaining_availability_duration] = 0 if stats[:remaining_availability_duration] < 0
    end

    stats
  end

  def update(availability)
    calculated_stats = calculate(availability)

    availability.update_columns(
      cached_stats: calculated_stats,
      cached_stats_updated_at: Time.current
    )

    calculated_stats
  end
end