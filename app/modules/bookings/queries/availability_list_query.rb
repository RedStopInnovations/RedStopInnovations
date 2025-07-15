module Bookings
  module Queries
    class AvailabilityListQuery
      def initialize(practitioner_id:, start_time:, end_time:, time_zone:)
        @start_time = start_time
        @end_time = end_time
        @time_zone = time_zone
        @practitioner_id = practitioner_id
      end

      def results
        availabilities = Availability
          .where(practitioner_id: @practitioner_id)
          # .where(allow_online_bookings: true)
          .where(availability_type_id: AvailabilityType::TYPE_HOME_VISIT_ID)
          .where(start_time: @start_time..@end_time)
          .where('appointments_count < max_appointment')
          .order(start_time: :asc)
          .to_a
      end
    end
  end
end