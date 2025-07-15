module Bookings
  class AvailableSlots
    attr_reader :availability, :appointment_duration, :slots

    def initialize(availability, appointment_duration)
      @availability = availability
      @appointment_duration = appointment_duration
      calculate_slots
    end

    def as_json(_options = {})
      @slots.map do |slot|
        {
          start_time: slot.start_time,
          end_time: slot.end_time
        }
      end
    end

    private

    def calculate_slots
      _slots = []
      avail_end_time = availability.end_time
      tmp_start = availability.start_time
      minutes_step = 15

      loop do
        end_time = tmp_start + appointment_duration.minutes
        break if end_time > avail_end_time
        break if tmp_start < Time.current

        overlapped = false
        availability.appointments.each do |appt|
          if (tmp_start < appt.end_time) && (end_time > appt.start_time)
            overlapped = true; break;
          end
        end

        unless overlapped
          _slots << OpenStruct.new(
            start_time: tmp_start,
            end_time: end_time
          )
        end
        tmp_start += minutes_step.minutes
      end
      @slots = _slots
    end
  end
end
